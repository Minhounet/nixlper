#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_logtail.sh
# DESCRIPTION: Offline unit tests for the log-tail feature (functions_logtail.sh).
#
# Pure bash, no external framework. The streaming happy-path is bounded with `timeout` so a
# real `tail -F` (which blocks forever waiting for new data) can never hang the suite.
# Run locally with:  bash src/test/bash/test_functions_logtail.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_logtail.sh"
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
echo "== argument validation =="
unset NIXLPER_LOGTAIL_IGNORE_CASE NIXLPER_LOGTAIL_LINES

out="$(_logtail 2>&1)"; rc=$?
_expect_match_count "missing args: error message" "${out}" "Usage: logtail" 1
_expect_eq "missing args: return 1" "${rc}" "1"

out="$(_logtail /tmp/only-one-arg 2>&1)"; rc=$?
_expect_match_count "missing pattern: error message" "${out}" "Usage: logtail" 1
_expect_eq "missing pattern: return 1" "${rc}" "1"

out="$(_logtail "${WORK_DIR}/does-not-exist.log" "ERROR" 2>&1)"; rc=$?
_expect_match_count "missing file: error message" "${out}" "File not found" 1
_expect_eq "missing file: return 1" "${rc}" "1"

echo "== grep flags =="
unset NIXLPER_LOGTAIL_IGNORE_CASE
_expect_match_count "default: no -i flag" "$(_i_logtail_grep_flags)" "(^| )-i( |$)" 0
export NIXLPER_LOGTAIL_IGNORE_CASE=true
_expect_match_count "ignore-case: -i flag present" "$(_i_logtail_grep_flags)" "(^| )-i( |$)" 1
unset NIXLPER_LOGTAIL_IGNORE_CASE

echo "== streaming happy path =="
LOG_FILE="${WORK_DIR}/app.log"
{
  echo "line one, nothing interesting"
  echo "line two ERROR boom"
  echo "line three, still fine"
} > "${LOG_FILE}"

# Strip ANSI colour codes (grep --color=always wraps the matched substring in them) so
# assertions can check plain text regardless of highlighting.
_strip_ansi() { sed -E $'s/\x1b\\[[0-9;]*[a-zA-Z]//g' <<< "$1"; }

out="$(timeout 1 bash -c "source '${LOGGING}'; source '${MODULE}'; _logtail '${LOG_FILE}' ERROR" 2>/dev/null)"
plain_out="$(_strip_ansi "${out}")"
_expect_match_count "matching line is printed" "${plain_out}" "line two ERROR boom" 1
_expect_match_count "highlighting escape codes present" "${out}" $'\x1b\\[' 1
_expect_match_count "non-matching lines are filtered out" "${plain_out}" "nothing interesting" 0

echo "== streaming, case-insensitive =="
out="$(NIXLPER_LOGTAIL_IGNORE_CASE=true timeout 1 bash -c "source '${LOGGING}'; source '${MODULE}'; _logtail '${LOG_FILE}' error" 2>/dev/null)"
plain_out="$(_strip_ansi "${out}")"
_expect_match_count "lowercase pattern matches uppercase ERROR" "${plain_out}" "line two ERROR boom" 1

#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "====================================================================================================="
echo "RESULT: ${PASS} passed, ${FAIL} failed"
echo "====================================================================================================="
[[ ${FAIL} -eq 0 ]]
