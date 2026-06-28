#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_recent_dirs.sh
# DESCRIPTION: Offline unit tests for the recent-directories feature (functions_recent_dirs.sh).
#
# Pure bash, no external framework. Run locally with:
#   bash src/test/bash/test_functions_recent_dirs.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_recent_dirs.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Isolated temp dir so tests never touch a real installation.
NIXLPER_TEST_TMP="$(mktemp -d)"
export NIXLPER_RECENT_DIRS_FILE="${NIXLPER_TEST_TMP}/recent_dirs"
export NIXLPER_RECENT_DIRS_MAX=5
export HOME="${NIXLPER_TEST_TMP}/home"  # prevent home-dir exclusion from firing on real $HOME
mkdir -p "$HOME"

trap 'rm -rf "${NIXLPER_TEST_TMP}"' EXIT

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

_expect_file_line_count() {
  local -r name="$1" file="$2" want="$3"
  local got=0
  [[ -f "$file" ]] && got=$(wc -l < "$file")
  _expect_eq "$name" "$got" "$want"
}

_expect_first_line() {
  local -r name="$1" file="$2" want="$3"
  local got=""
  [[ -f "$file" ]] && got=$(head -1 "$file")
  _expect_eq "$name" "$got" "$want"
}

#-----------------------------------------------------------------------------------------------------------------------
# Tests
#-----------------------------------------------------------------------------------------------------------------------

echo ""
echo "=== Recent dirs: tracking ==="

# Basic tracking — file is created and contains the dir.
rm -f "${NIXLPER_RECENT_DIRS_FILE}"
PWD="/some/project" _i_recent_dirs_track
_expect_first_line "track: first entry written" "${NIXLPER_RECENT_DIRS_FILE}" "/some/project"
_expect_file_line_count "track: file has 1 line" "${NIXLPER_RECENT_DIRS_FILE}" 1

# Second different dir is prepended (most recent first).
PWD="/another/dir" _i_recent_dirs_track
_expect_first_line "track: second dir is on top" "${NIXLPER_RECENT_DIRS_FILE}" "/another/dir"
_expect_file_line_count "track: file has 2 lines" "${NIXLPER_RECENT_DIRS_FILE}" 2

# Re-visiting first dir deduplicates it to the top.
PWD="/some/project" _i_recent_dirs_track
_expect_first_line "track: revisited dir bubbles to top" "${NIXLPER_RECENT_DIRS_FILE}" "/some/project"
_expect_file_line_count "track: still 2 lines after dedup" "${NIXLPER_RECENT_DIRS_FILE}" 2

# Cap at NIXLPER_RECENT_DIRS_MAX.
rm -f "${NIXLPER_RECENT_DIRS_FILE}"
for i in 1 2 3 4 5 6 7; do
  PWD="/dir/number${i}" _i_recent_dirs_track
done
_expect_file_line_count "track: capped at max (5)" "${NIXLPER_RECENT_DIRS_FILE}" 5
_expect_first_line "track: newest is on top after cap" "${NIXLPER_RECENT_DIRS_FILE}" "/dir/number7"

echo ""
echo "=== Recent dirs: home/root exclusion ==="

rm -f "${NIXLPER_RECENT_DIRS_FILE}"
PWD="${HOME}" _i_recent_dirs_track
local_count=0; [[ -f "${NIXLPER_RECENT_DIRS_FILE}" ]] && local_count=$(wc -l < "${NIXLPER_RECENT_DIRS_FILE}")
_expect_eq "track: home dir is excluded" "$local_count" "0"

PWD="/" _i_recent_dirs_track
local_count=0; [[ -f "${NIXLPER_RECENT_DIRS_FILE}" ]] && local_count=$(wc -l < "${NIXLPER_RECENT_DIRS_FILE}")
_expect_eq "track: root is excluded" "$local_count" "0"

echo ""
echo "=== Recent dirs: _i_recent_dirs_init ==="

unset PROMPT_COMMAND
_i_recent_dirs_init
_expect_eq "init: hook added to PROMPT_COMMAND" "${PROMPT_COMMAND}" "_i_recent_dirs_track"

_i_recent_dirs_init
_expect_eq "init: calling twice does not duplicate hook" "${PROMPT_COMMAND}" "_i_recent_dirs_track"

PROMPT_COMMAND="existing_hook"
_i_recent_dirs_init
_expect_eq "init: prepended to existing PROMPT_COMMAND" "${PROMPT_COMMAND}" "_i_recent_dirs_track; existing_hook"

echo ""
echo "=== Recent dirs: _i_recent_dirs_file path resolution ==="

unset NIXLPER_RECENT_DIRS_FILE
expected="${HOME}/.local/share/nixlper/recent_dirs"
got=$(_i_recent_dirs_file)
_expect_eq "file: default path uses HOME" "$got" "$expected"

export NIXLPER_RECENT_DIRS_FILE="/custom/path/recent"
got=$(_i_recent_dirs_file)
_expect_eq "file: custom path respected" "$got" "/custom/path/recent"
export NIXLPER_RECENT_DIRS_FILE="${NIXLPER_TEST_TMP}/recent_dirs"

#-----------------------------------------------------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "────────────────────────────────────"
[[ ${FAIL} -eq 0 ]]
