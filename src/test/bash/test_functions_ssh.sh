#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_ssh.sh
# DESCRIPTION: Offline unit tests for the SSH connection manager (functions_ssh.sh).
#
# Pure bash, no external framework. ssh, ssh-keygen, ssh-copy-id, and fzf are mocked
# so tests run deterministically without a network or a real SSH server.
# Run locally with:  bash src/test/bash/test_functions_ssh.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_ssh.sh"
LOGGING="${REPO_ROOT}/src/main/bash/functions_logging.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Isolated temp dir — all file paths live here, nothing touches the real home.
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_TEST}"' EXIT

export NIXLPER_SSH_CONNECTIONS_FILE="${TMPDIR_TEST}/ssh_connections"
export NIXLPER_SSH_IDENTITY_FILE="${TMPDIR_TEST}/nixlper_id_rsa"

# Source logging shim (or stub if unavailable)
if [[ -f "${LOGGING}" ]]; then
  # shellcheck source=/dev/null
  source "${LOGGING}"
else
  _i_log_as_info()  { echo "INFO:  $*"; }
  _i_log_as_error() { echo "ERROR: $*"; }
fi

# shellcheck source=/dev/null
source "${MODULE}"

#-----------------------------------------------------------------------------------------------------------------------
# Assertion helpers (same pattern as test_functions_update.sh)
#-----------------------------------------------------------------------------------------------------------------------
PASS=0
FAIL=0

_expect_eq() {
  local -r name="$1" got="$2" want="$3"
  if [[ "${got}" == "${want}" ]]; then
    echo "  ✅ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: got [${got}] want [${want}]"
    FAIL=$((FAIL + 1))
  fi
}

_expect_true() {
  local -r name="$1"; shift
  if "$@" 2>/dev/null; then
    echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: expected success"; FAIL=$((FAIL + 1))
  fi
}

_expect_false() {
  local -r name="$1"; shift
  if "$@" 2>/dev/null; then
    echo "  ❌ ${name}: expected failure"; FAIL=$((FAIL + 1))
  else
    echo "  ✅ ${name}"; PASS=$((PASS + 1))
  fi
}

_reset_connections() {
  rm -f "${NIXLPER_SSH_CONNECTIONS_FILE}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Mocks — replace tools that require a real SSH server or terminal
#-----------------------------------------------------------------------------------------------------------------------
ssh-keygen() { touch "${NIXLPER_SSH_IDENTITY_FILE}" "${NIXLPER_SSH_IDENTITY_FILE}.pub"; return 0; }
ssh-copy-id() { return 0; }
ssh()        { return 0; }
fzf()        { cat; }   # fzf passthrough: returns first line of stdin

#-----------------------------------------------------------------------------------------------------------------------
# Tests — _i_ssh_load_connections
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "── _i_ssh_load_connections ─────────────────────────────────────────────────"

_reset_connections
result=$(_i_ssh_load_connections)
_expect_eq "missing file returns empty" "${result}" ""

touch "${NIXLPER_SSH_CONNECTIONS_FILE}"
result=$(_i_ssh_load_connections)
_expect_eq "empty file returns empty" "${result}" ""

printf '# comment line\n\n  # indented comment\n' > "${NIXLPER_SSH_CONNECTIONS_FILE}"
result=$(_i_ssh_load_connections)
_expect_eq "comment-only file returns empty" "${result}" ""

printf 'myserver|alice|1.2.3.4|22|\n# comment\nwork|bob|10.0.0.1|2222|/home/bob/.ssh/id_rsa\n' \
  > "${NIXLPER_SSH_CONNECTIONS_FILE}"
result=$(_i_ssh_load_connections)
line_count=$(echo "${result}" | grep -c '|')
_expect_eq "two valid entries loaded" "${line_count}" "2"

#-----------------------------------------------------------------------------------------------------------------------
# Tests — _i_ssh_parse_field
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "── _i_ssh_parse_field ──────────────────────────────────────────────────────"

line="work|bob|10.0.0.1|2222|/home/bob/.ssh/id_rsa"
_expect_eq "field 1 = label"  "$(_i_ssh_parse_field "${line}" 1)" "work"
_expect_eq "field 2 = user"   "$(_i_ssh_parse_field "${line}" 2)" "bob"
_expect_eq "field 3 = host"   "$(_i_ssh_parse_field "${line}" 3)" "10.0.0.1"
_expect_eq "field 4 = port"   "$(_i_ssh_parse_field "${line}" 4)" "2222"
_expect_eq "field 5 = key"    "$(_i_ssh_parse_field "${line}" 5)" "/home/bob/.ssh/id_rsa"

line_empty_key="myserver|alice|1.2.3.4|22|"
_expect_eq "field 5 empty key = empty string" "$(_i_ssh_parse_field "${line_empty_key}" 5)" ""

#-----------------------------------------------------------------------------------------------------------------------
# Tests — _i_ssh_ensure_key
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "── _i_ssh_ensure_key ───────────────────────────────────────────────────────"

rm -f "${NIXLPER_SSH_IDENTITY_FILE}" "${NIXLPER_SSH_IDENTITY_FILE}.pub"
_i_ssh_ensure_key
_expect_true "key file created when missing" test -f "${NIXLPER_SSH_IDENTITY_FILE}"

# Second call must not re-create (ssh-keygen mock always succeeds, but key already exists → no-op)
call_count=0
ssh-keygen() { call_count=$((call_count+1)); touch "${NIXLPER_SSH_IDENTITY_FILE}"; }
_i_ssh_ensure_key
_expect_eq "key already present → ssh-keygen not called again" "${call_count}" "0"
# Restore mock
ssh-keygen() { touch "${NIXLPER_SSH_IDENTITY_FILE}" "${NIXLPER_SSH_IDENTITY_FILE}.pub"; return 0; }

#-----------------------------------------------------------------------------------------------------------------------
# Tests — sca (add connection)
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "── sca ─────────────────────────────────────────────────────────────────────"

_reset_connections

# Simulate: label=prod, user=deploy, host=prod.example.com, port=22, key=(empty)
sca_output=$(printf 'prod\ndeploy\nprod.example.com\n22\n\n' | sca 2>&1)
conn_line=$(grep '^prod|' "${NIXLPER_SSH_CONNECTIONS_FILE}" 2>/dev/null || true)
_expect_eq "connection written to file"     "${conn_line}" "prod|deploy|prod.example.com|22|"

# Duplicate label rejected
printf 'prod\n' | sca 2>&1
count=$(grep -c '^prod|' "${NIXLPER_SSH_CONNECTIONS_FILE}")
_expect_eq "duplicate label rejected" "${count}" "1"

# Empty label rejected
empty_output=$(printf '\n' | sca 2>&1)
_expect_eq "empty label error shown" "$(echo "${empty_output}" | grep -ci 'empty')" "1"

# Label with space rejected
space_output=$(printf 'my server\n' | sca 2>&1)
_expect_eq "label with space rejected" "$(echo "${space_output}" | grep -ci 'space\|pipe')" "1"

# Label with pipe rejected — pipe_output first word is "my" so label="my", then "|label" shifts fields but we feed it raw
pipe_output=$(printf 'my|label\n' | sca 2>&1)
_expect_eq "label with pipe rejected" "$(echo "${pipe_output}" | grep -ci 'space\|pipe')" "1"

# Invalid port — non-numeric
inv_port=$(printf 'testport\nalice\n1.2.3.4\nabc\n\n' | sca 2>&1)
_expect_eq "non-numeric port rejected" "$(echo "${inv_port}" | grep -ci 'invalid port\|port')" "1"
no_testport=$(grep '^testport|' "${NIXLPER_SSH_CONNECTIONS_FILE}" 2>/dev/null | wc -l)
_expect_eq "non-numeric port: nothing written" "${no_testport// /}" "0"

# Out-of-range port
inv_port2=$(printf 'testport2\nalice\n1.2.3.4\n99999\n\n' | sca 2>&1)
_expect_eq "out-of-range port rejected" "$(echo "${inv_port2}" | grep -ci 'invalid port\|port')" "1"

# Custom port stored correctly
printf 'staging\nci\nstaging.local\n2222\n\n' | sca 2>&1
staging_line=$(grep '^staging|' "${NIXLPER_SSH_CONNECTIONS_FILE}" 2>/dev/null || true)
_expect_eq "custom port stored"             "${staging_line}" "staging|ci|staging.local|2222|"

#-----------------------------------------------------------------------------------------------------------------------
# Tests — scr (remove connection)
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "── scr ─────────────────────────────────────────────────────────────────────"

_reset_connections
printf 'a|u|h|22|\nb|u|h|22|\nc|u|h|22|\n' > "${NIXLPER_SSH_CONNECTIONS_FILE}"

# fzf mock: return first line of stdin (= first label)
fzf() { head -1; }

# scr confirmation: "y"
printf 'y\n' | scr 2>&1
remaining=$(_i_ssh_load_connections)
still_has_a=$(echo "${remaining}" | grep -c '^a|' || true)
_expect_eq "removed entry gone" "${still_has_a}" "0"

still_has_b=$(echo "${remaining}" | grep -c '^b|')
still_has_c=$(echo "${remaining}" | grep -c '^c|')
_expect_eq "other entries preserved (b)" "${still_has_b}" "1"
_expect_eq "other entries preserved (c)" "${still_has_c}" "1"

# scr with "n" → no change
printf 'n\n' | scr 2>&1
count_after=$(_i_ssh_load_connections | grep -c '|')
_expect_eq "cancel leaves entries intact" "${count_after}" "2"

# Restore fzf passthrough
fzf() { cat; }

#-----------------------------------------------------------------------------------------------------------------------
# Tests — scl (list connections)
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "── scl ─────────────────────────────────────────────────────────────────────"

_reset_connections
scl_empty=$(scl 2>&1)
_expect_eq "empty list message shown" "$(echo "${scl_empty}" | grep -ci 'no ssh\|sca')" "1"

printf 'myserver|alice|1.2.3.4|22|\n' > "${NIXLPER_SSH_CONNECTIONS_FILE}"
scl_output=$(scl 2>&1)
_expect_eq "label appears in list"   "$(echo "${scl_output}" | grep -c 'myserver')" "1"
_expect_eq "host appears in list"    "$(echo "${scl_output}" | grep -c '1.2.3.4')"  "1"
_expect_eq "empty key shows default" "$(echo "${scl_output}" | grep -c 'global default')" "1"

#-----------------------------------------------------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════════"
[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
