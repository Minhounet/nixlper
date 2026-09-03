#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_last_command.sh
# DESCRIPTION: Offline unit tests for the command-history feature (functions_last_command.sh).
#
# Pure bash, no external framework, no dependency on a real interactive shell history:
# _i_last_command_history_raw is overridden with a mock feeding canned history text.
# Run locally with:
#   bash src/test/bash/test_functions_last_command.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_last_command.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Stub logging functions used by the module.
_i_log_as_info()  { :; }
_i_log_as_error() { :; }

# shellcheck source=/dev/null
source "${MODULE}"

#-----------------------------------------------------------------------------------------------------------------------
# Assertion helpers
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

# Mock: feed canned "history"-formatted text (oldest first, as the real builtin prints it) to
# _i_last_command_history_raw's downstream consumers, applying the same processing (reverse +
# strip leading index) the real implementation does.
_mock_history() {
  printf '%s\n' "$@" | tac | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//'
}

#-----------------------------------------------------------------------------------------------------------------------
# Tests
#-----------------------------------------------------------------------------------------------------------------------

echo ""
echo "=== last_command: _i_last_command_list ordering and dedup ==="

_i_last_command_history_raw() {
  _mock_history "  1  git status" "  2  ls -la" "  3  git status"
}
unset NIXLPER_LAST_COMMAND_MAX
result=$(_i_last_command_list)
_expect_eq "list: most recent occurrence wins, dedup keeps 2 entries" "$(printf '%s\n' "${result}" | wc -l | tr -d ' ')" "2"
_expect_eq "list: newest command is on top" "$(printf '%s\n' "${result}" | head -1)" "git status"
_expect_eq "list: older unique command follows" "$(printf '%s\n' "${result}" | sed -n 2p)" "ls -la"

echo ""
echo "=== last_command: blank lines and self-invocations skipped ==="

_i_last_command_history_raw() {
  _mock_history "  1  echo hi" "  2  " "  3  lc" "  4  last_command" "  5  echo bye"
}
result=$(_i_last_command_list)
_expect_eq "list: blank/self-invocation lines filtered, 2 entries remain" "$(printf '%s\n' "${result}" | wc -l | tr -d ' ')" "2"
_expect_eq "list: newest real command first" "$(printf '%s\n' "${result}" | head -1)" "echo bye"
_expect_eq "list: older real command second" "$(printf '%s\n' "${result}" | sed -n 2p)" "echo hi"

echo ""
echo "=== last_command: NIXLPER_LAST_COMMAND_MAX caps the list ==="

_i_last_command_history_raw() {
  _mock_history "  1  cmd1" "  2  cmd2" "  3  cmd3" "  4  cmd4" "  5  cmd5"
}
export NIXLPER_LAST_COMMAND_MAX=2
result=$(_i_last_command_list)
_expect_eq "list: capped at max (2)" "$(printf '%s\n' "${result}" | wc -l | tr -d ' ')" "2"
_expect_eq "list: newest entry still on top after cap" "$(printf '%s\n' "${result}" | head -1)" "cmd5"
unset NIXLPER_LAST_COMMAND_MAX

echo ""
echo "=== last_command: _i_last_command_indexed_list ==="

_i_last_command_history_raw() {
  _mock_history "  1  first" "  2  second"
}
result=$(_i_last_command_indexed_list)
_expect_eq "indexed: first entry numbered 1" "$(printf '%s\n' "${result}" | sed -n 1p)" "1  second"
_expect_eq "indexed: second entry numbered 2" "$(printf '%s\n' "${result}" | sed -n 2p)" "2  first"

echo ""
echo "=== last_command: empty history ==="

_i_last_command_history_raw() { :; }
result=$(_i_last_command_list)
_expect_eq "list: empty history yields empty list" "${result}" ""

echo ""
echo "=== last_command: no fzf falls back to numbered picker ==="

_i_last_command_history_raw() {
  _mock_history "  1  echo test"
}
command() {  # shadow the `command` builtin so `command -v fzf` reports "not installed"
  if [[ "$1" == "-v" && "$2" == "fzf" ]]; then
    return 1
  fi
  builtin command "$@"
}
_i_last_command_numbered_pick() { echo "numbered_pick_called"; }
_i_last_command_fuzzy_pick() { echo "fuzzy_pick_called"; }
result=$(last_command)
_expect_eq "last_command: uses numbered picker when fzf is unavailable" "${result}" "numbered_pick_called"
unset -f command

#-----------------------------------------------------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "────────────────────────────────────"
[[ ${FAIL} -eq 0 ]]
