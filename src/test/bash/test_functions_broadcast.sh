#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_broadcast.sh
# DESCRIPTION: Offline unit tests for the admin broadcast message feature (functions_broadcast.sh).
# Run locally with:  bash src/test/bash/test_functions_broadcast.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_broadcast.sh"
LOGGING="${REPO_ROOT}/src/main/bash/functions_logging.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${LOGGING}"
# shellcheck source=/dev/null
source "${MODULE}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

export NIXLPER_INSTALL_DIR="${WORK_DIR}"
unset NIXLPER_BROADCAST_MESSAGE_FILE NIXLPER_DISABLE_BROADCAST_MESSAGE

#-----------------------------------------------------------------------------------------------------------------------
# Tiny assertion helpers
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

_expect_match_count() {  # $1 name, $2 haystack, $3 regex, $4 expected count
  local -r name="$1" haystack="$2" regex="$3" want="$4"
  local got
  got="$(printf '%s\n' "${haystack}" | grep -c -E "${regex}")"
  _expect_eq "${name}" "${got}" "${want}"
}

#-----------------------------------------------------------------------------------------------------------------------
echo "== no notice registered =="
_i_broadcast_active
_expect_eq "inactive when file absent" "$?" "1"

out="$(show_broadcast_message 2>&1)"
_expect_match_count "bshow reports nothing set" "${out}" "No admin notice currently set" 1

echo "== bclear with nothing to clear =="
out="$(clear_broadcast_message 2>&1)"; rc=$?
_expect_match_count "bclear on empty: info message" "${out}" "No admin notice currently set" 1
_expect_eq "bclear on empty: return 0" "${rc}" "0"

echo "== persistent notice (blank expiry) =="
out="$(printf 'Kernel patched, reboot pending\n\n' | set_broadcast_message 2>&1)"
_expect_match_count "bset: persistent confirmation" "${out}" "persistent until bclear" 1

_i_broadcast_active
_expect_eq "active right after set" "$?" "0"

file="$(_i_broadcast_message_file)"
_expect_eq "message file content" "$(cat "${file}")" "Kernel patched, reboot pending"
_expect_eq "no expiry sidecar for persistent notice" "$( [[ -f "${file}.expires" ]] && echo yes || echo no )" "no"

show_out="$(show_broadcast_message 2>&1)"
_expect_match_count "bshow prints the message" "${show_out}" "Kernel patched, reboot pending" 1
_expect_match_count "bshow prints admin banner" "${show_out}" "ADMIN NOTICE" 1

echo "== login hook prints the active notice, unless disabled =="
login_out="$(_i_load_broadcast_message 2>&1)"
_expect_match_count "login hook shows the notice" "${login_out}" "Kernel patched, reboot pending" 1

export NIXLPER_DISABLE_BROADCAST_MESSAGE=true
login_out="$(_i_load_broadcast_message 2>&1)"
_expect_eq "login hook silent when disabled" "${login_out}" ""
unset NIXLPER_DISABLE_BROADCAST_MESSAGE

echo "== bclear removes it =="
out="$(clear_broadcast_message 2>&1)"
_expect_match_count "bclear: confirmation" "${out}" "Admin notice cleared" 1
_i_broadcast_active
_expect_eq "inactive after clear" "$?" "1"

echo "== expiring notice (0 days = already expired) =="
out="$(printf 'Temporary DNS workaround\n0\n' | set_broadcast_message 2>&1)"
_expect_match_count "bset: expiry confirmation" "${out}" "expires in 0 day" 1
_expect_eq "expiry sidecar written" "$( [[ -f "${file}.expires" ]] && echo yes || echo no )" "yes"

_i_broadcast_active
_expect_eq "0-day notice reports expired" "$?" "1"
_expect_eq "expired notice file cleaned up" "$( [[ -f "${file}" ]] && echo yes || echo no )" "no"
_expect_eq "expired sidecar cleaned up" "$( [[ -f "${file}.expires" ]] && echo yes || echo no )" "no"

echo "== expiring notice (future date stays active) =="
out="$(printf 'Maintenance window this weekend\n3\n' | set_broadcast_message 2>&1)"
_i_broadcast_active
_expect_eq "future-dated notice stays active" "$?" "0"
clear_broadcast_message >/dev/null 2>&1

echo "== invalid expiry falls back to persistent =="
out="$(printf 'Bad expiry input\nabc\n' | set_broadcast_message 2>&1)"
_expect_match_count "bset: invalid days warning" "${out}" "not a valid number of days" 1
_i_broadcast_active
_expect_eq "notice still active despite bad expiry" "$?" "0"
_expect_eq "no expiry sidecar written on invalid input" "$( [[ -f "${file}.expires" ]] && echo yes || echo no )" "no"
clear_broadcast_message >/dev/null 2>&1

echo "== empty message is rejected =="
out="$(printf '\n' | set_broadcast_message 2>&1)"; rc=$?
_expect_match_count "bset: empty message error" "${out}" "Empty message, aborted" 1
_expect_eq "bset: empty message return 1" "${rc}" "1"

#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "====================================================================================================="
echo "RESULT: ${PASS} passed, ${FAIL} failed"
echo "====================================================================================================="
[[ ${FAIL} -eq 0 ]]
