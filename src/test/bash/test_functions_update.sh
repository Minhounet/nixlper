#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_update.sh
# DESCRIPTION: Offline unit tests for the update-detection feature (functions_update.sh).
#
# These tests are dependency-free (pure bash) and never touch the network: the reachability
# probe and the GitHub lookups are overridden with mocks, so they run deterministically in CI.
# Run locally with:  bash src/test/bash/test_functions_update.sh
########################################################################################################################
set -u

# Resolve repo root from this script's location so it works from any CWD (incl. CI).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_update.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Isolated, throwaway install dir / cache so tests never read or write a real installation.
export NIXLPER_INSTALL_DIR="$(mktemp -d)"
export NIXLPER_UPDATE_CACHE_FILE="${NIXLPER_INSTALL_DIR}/.nixlper_update_check"
trap 'rm -rf "${NIXLPER_INSTALL_DIR}"' EXIT

# shellcheck source=/dev/null
source "${MODULE}"

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

# $3 = expected count of lines matching the regex in $2 (stdout+stderr of last captured run)
_expect_match_count() {
  local -r name="$1" haystack="$2" regex="$3" want="$4"
  local got
  got="$(printf '%s\n' "${haystack}" | grep -c -E "${regex}")"
  _expect_eq "${name}" "${got}" "${want}"
}

_expect_true() {  # $2 is a command; passes if it returns 0
  local -r name="$1"; shift
  if "$@"; then echo "  ✅ ${name}"; PASS=$((PASS + 1)); else echo "  ❌ ${name}: expected success"; FAIL=$((FAIL + 1)); fi
}

_expect_false() {  # passes if command returns non-zero
  local -r name="$1"; shift
  if "$@"; then echo "  ❌ ${name}: expected failure"; FAIL=$((FAIL + 1)); else echo "  ✅ ${name}"; PASS=$((PASS + 1)); fi
}

_write_version() {  # $1 VERSION value (may be empty), $2 COMMIT value (may be empty)
  {
    echo "PROJECT: nixlper"
    [[ -n "${1:-}" ]] && echo "VERSION: $1"
    echo "TECHNICAL VERSION: abc123 (2026-01-01)"
    [[ -n "${2:-}" ]] && echo "COMMIT: $2"
  } > "${NIXLPER_INSTALL_DIR}/version"
}

_reset_throttle() { rm -f "${NIXLPER_UPDATE_CACHE_FILE}"; }

# Default mocks — individual tests override as needed.
_i_is_online() { return 0; }
_i_remote_latest_tag() { echo ""; }
_i_remote_edge_release_commit() { echo ""; }

#-----------------------------------------------------------------------------------------------------------------------
echo "== _i_version_gt =="
_expect_true  "2.1.0 > 2.0.1"            _i_version_gt v2.1.0 v2.0.1
_expect_false "2.0.1 not > 2.1.0"        _i_version_gt v2.0.1 v2.1.0
_expect_false "equal is not greater"     _i_version_gt v2.0.1 v2.0.1
_expect_true  "2.0.10 > 2.0.9 (numeric)" _i_version_gt v2.0.10 v2.0.9

echo "== version file parsing =="
_write_version "v2.0.1" "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
_expect_eq "VERSION field" "$(_i_installed_version_field 'VERSION:')" "v2.0.1"
_expect_eq "COMMIT field"  "$(_i_installed_version_field 'COMMIT:')" "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
_write_version "" ""
_expect_eq "missing VERSION -> empty" "$(_i_installed_version_field 'VERSION:')" ""

echo "== throttle =="
_reset_throttle
_expect_true  "due when no cache exists"  _i_update_check_due
_i_update_touch_cache
_expect_false "not due right after stamp" _i_update_check_due
echo "garbage" > "${NIXLPER_UPDATE_CACHE_FILE}"
_expect_true  "due when cache is corrupt" _i_update_check_due

echo "== channel: off =="
export NIXLPER_UPDATE_CHANNEL=off
_reset_throttle
_expect_eq "off + auto is silent" "$(_i_check_for_updates 2>&1)" ""
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "off + force explains" "${out}" "disabled" 1

echo "== channel: NIXLPER_UPDATE_CHECK=false =="
export NIXLPER_UPDATE_CHANNEL=stable
export NIXLPER_UPDATE_CHECK=false
_reset_throttle
_expect_eq "check=false auto silent" "$(_i_check_for_updates 2>&1)" ""
unset NIXLPER_UPDATE_CHECK

echo "== offline guard =="
export NIXLPER_UPDATE_CHANNEL=stable
_i_is_online() { return 1; }
_reset_throttle
_expect_eq "offline auto is silent" "$(_i_check_for_updates 2>&1)" ""
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "offline force reports" "${out}" "not reachable" 1
_i_is_online() { return 0; }

echo "== stable channel =="
_write_version "v2.0.1" ""
_i_remote_latest_tag() { echo "v2.1.0"; }
_reset_throttle
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "newer tag notifies" "${out}" "v2.1.0 is available" 1
_i_remote_latest_tag() { echo "v2.0.1"; }
_reset_throttle
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "same tag: up to date (force)" "${out}" "up to date" 1
_reset_throttle
_expect_eq "same tag: silent on auto" "$(_i_check_for_updates 2>&1)" ""
# Installed newer than remote (dev build) must NOT suggest a downgrade.
_write_version "v2.5.0" ""
_i_remote_latest_tag() { echo "v2.1.0"; }
_reset_throttle
out="$(_i_check_for_updates 2>&1)"
_expect_eq "newer-than-remote: no downgrade noise" "${out}" ""

echo "== edge channel =="
export NIXLPER_UPDATE_CHANNEL=edge
_write_version "" "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
_i_remote_edge_release_commit() { echo "1111111111111111111111111111111111111111"; }
_reset_throttle
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "new commit notifies" "${out}" "newer Nixlper commit" 1
_i_remote_edge_release_commit() { echo "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"; }
_reset_throttle
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "same commit: up to date" "${out}" "latest commit" 1

echo "== unknown channel =="
export NIXLPER_UPDATE_CHANNEL=bogus
_reset_throttle
out="$(_i_check_for_updates true 2>&1)"
_expect_match_count "unknown channel warns" "${out}" "Unknown NIXLPER_UPDATE_CHANNEL" 1

#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "====================================================================================================="
echo "RESULT: ${PASS} passed, ${FAIL} failed"
echo "====================================================================================================="
[[ ${FAIL} -eq 0 ]]
