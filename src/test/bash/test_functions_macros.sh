#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_macros.sh
# DESCRIPTION: Unit tests for the PROMPT_COMMAND-based macro recording (functions_macros.sh).
#
# Pure bash, no external framework. Run with: bash src/test/bash/test_functions_macros.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_macros.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Stub out log helpers so test output is clean.
_i_log_as_info()  { :; }
_i_log_as_error() { :; }
_i_log_ok()       { :; }
# Suppress bind in non-interactive environment.
bind() { return 0; }

export NIXLPER_LAST_MACRO_BINDING_FILE
NIXLPER_LAST_MACRO_BINDING_FILE=$(mktemp)
trap 'rm -f "${NIXLPER_LAST_MACRO_BINDING_FILE}"' EXIT

# shellcheck source=/dev/null
source "${MODULE}"

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

_expect_contains() {
  local -r name="$1" haystack="$2" needle="$3"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    echo "  ✅ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: expected [${needle}] in [${haystack}]"
    FAIL=$((FAIL + 1))
  fi
}

_expect_not_contains() {
  local -r name="$1" haystack="$2" needle="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "  ✅ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: [${needle}] should not be in [${haystack}]"
    FAIL=$((FAIL + 1))
  fi
}

########################################################################################################################
echo "--- start_recording ---"
########################################################################################################################

PROMPT_COMMAND=""
_i_get_last_hist_num() { echo "5"; }
start_recording
_expect_eq "sets _NIXLPER_RECORDING=true" "true" "${_NIXLPER_RECORDING}"
_expect_eq "initializes _NIXLPER_LAST_HIST_NUM from current history position" "5" "${_NIXLPER_LAST_HIST_NUM}"

PROMPT_COMMAND=""
_i_get_last_hist_num() { echo "5"; }
start_recording
_expect_contains "injects hook into PROMPT_COMMAND" "${PROMPT_COMMAND}" "_i_macro_record_step"

PROMPT_COMMAND="other_stuff"
start_recording
_expect_contains "hook prepended before existing PROMPT_COMMAND" "${PROMPT_COMMAND}" "_i_macro_record_step; other_stuff"

_NIXLPER_MACRO_COMMANDS=("stale" "command")
start_recording
_expect_eq "clears command array" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"

PROMPT_COMMAND=""
start_recording
start_recording
count=$(echo "${PROMPT_COMMAND}" | grep -o "_i_macro_record_step" | wc -l | tr -d ' ')
_expect_eq "does not inject hook twice" "1" "${count}"

########################################################################################################################
echo "--- _i_macro_record_step ---"
########################################################################################################################

_NIXLPER_RECORDING=false
_NIXLPER_MACRO_COMMANDS=()
_i_get_last_hist_num() { echo "1"; }
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "does nothing when not recording" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"

_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_NIXLPER_LAST_HIST_NUM=0
_i_get_last_hist_num() { echo "1"; }
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "appends regular command" "1" "${#_NIXLPER_MACRO_COMMANDS[@]}"
_expect_eq "captures correct command text" "ls -la" "${_NIXLPER_MACRO_COMMANDS[0]}"

_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_NIXLPER_LAST_HIST_NUM=0
_i_get_last_hist_num() { echo "1"; }
_i_get_last_cmd() { echo ""; }
_i_macro_record_step
_expect_eq "ignores empty command" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"

for skip_cmd in sr fr start_recording finalize_recording; do
  _NIXLPER_RECORDING=true
  _NIXLPER_MACRO_COMMANDS=()
  _NIXLPER_LAST_HIST_NUM=0
  _i_get_last_hist_num() { echo "1"; }
  _i_get_last_cmd() { echo "${skip_cmd}"; }
  _i_macro_record_step
  _expect_eq "skips '${skip_cmd}'" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"
done

# HISTCONTROL: history number unchanged = command excluded from history (ignorespace/ignoredups).
_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_NIXLPER_LAST_HIST_NUM=42
_i_get_last_hist_num() { echo "42"; }
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "skips when history number unchanged (HISTCONTROL)" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"

# History number changed = new entry added, capture it.
_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_NIXLPER_LAST_HIST_NUM=42
_i_get_last_hist_num() { echo "43"; }
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "captures when history number advances" "1" "${#_NIXLPER_MACRO_COMMANDS[@]}"

# _NIXLPER_LAST_HIST_NUM advances after each captured command.
_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_NIXLPER_LAST_HIST_NUM=42
_i_get_last_hist_num() { echo "43"; }
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "advances _NIXLPER_LAST_HIST_NUM after capture" "43" "${_NIXLPER_LAST_HIST_NUM}"

_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_NIXLPER_LAST_HIST_NUM=0
# Returns LAST_HIST_NUM+1 each call; since the step function updates LAST_HIST_NUM
# in the parent shell, successive calls produce 1, 2, 3 — simulating three new entries.
_i_get_last_hist_num() { echo $(( _NIXLPER_LAST_HIST_NUM + 1 )); }
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_i_get_last_cmd() { echo "cd /tmp"; }
_i_macro_record_step
_i_get_last_cmd() { echo "pwd"; }
_i_macro_record_step
_expect_eq "accumulates multiple commands" "3" "${#_NIXLPER_MACRO_COMMANDS[@]}"

########################################################################################################################
echo "--- finalize_recording ---"
########################################################################################################################

# Mock _prepare_binding to isolate state tests from bind calls.
# Save the original body so we can restore it after the state tests.
_saved_prepare_binding="$(declare -f _prepare_binding)"
_prepare_binding() { :; }

_NIXLPER_RECORDING=true
PROMPT_COMMAND="_i_macro_record_step; old_stuff"
_NIXLPER_MACRO_COMMANDS=("ls -la")
finalize_recording
_expect_eq "sets _NIXLPER_RECORDING=false" "false" "${_NIXLPER_RECORDING}"

_NIXLPER_RECORDING=true
PROMPT_COMMAND="_i_macro_record_step; old_stuff"
_NIXLPER_MACRO_COMMANDS=("ls -la")
finalize_recording
_expect_not_contains "removes hook from PROMPT_COMMAND" "${PROMPT_COMMAND}" "_i_macro_record_step"

_NIXLPER_RECORDING=true
PROMPT_COMMAND="_i_macro_record_step; old_stuff"
_NIXLPER_MACRO_COMMANDS=("ls -la")
finalize_recording
_expect_eq "preserves rest of PROMPT_COMMAND" "old_stuff" "${PROMPT_COMMAND}"

_NIXLPER_RECORDING=true
PROMPT_COMMAND="_i_macro_record_step"
_NIXLPER_MACRO_COMMANDS=("ls -la")
finalize_recording
_expect_eq "removes hook when it is the only entry" "" "${PROMPT_COMMAND}"

# Restore real _prepare_binding.
eval "${_saved_prepare_binding}"

########################################################################################################################
echo "--- _prepare_binding ---"
########################################################################################################################

_NIXLPER_MACRO_COMMANDS=()
_prepare_binding
_expect_eq "returns 1 on empty array" "1" "$?"

_NIXLPER_MACRO_COMMANDS=("ls -la" "cd /tmp")
_prepare_binding
_expect_eq "returns 0 with commands" "0" "$?"

_NIXLPER_MACRO_COMMANDS=("ls -la" "cd /tmp")
_prepare_binding
file_content=$(cat "${NIXLPER_LAST_MACRO_BINDING_FILE}")
_expect_contains "binding file contains first command" "${file_content}" "ls -la"
_expect_contains "binding file contains second command" "${file_content}" "cd /tmp"
_expect_contains "binding file defines replay function" "${file_content}" "_nixlper_macro_replay"
_expect_contains "binding file contains bind statement" "${file_content}" "bind -x"

# Single quotes must survive into the function body without breaking the file.
_NIXLPER_MACRO_COMMANDS=("echo 'hello world'" "grep 'foo bar' file.txt")
_prepare_binding
file_content=$(cat "${NIXLPER_LAST_MACRO_BINDING_FILE}")
_expect_contains "single quotes preserved in binding file" "${file_content}" "echo 'hello world'"
_expect_contains "single quotes in second command preserved" "${file_content}" "grep 'foo bar' file.txt"
# Verify the file is valid bash syntax (would fail if quoting was broken).
bash -n "${NIXLPER_LAST_MACRO_BINDING_FILE}"
_expect_eq "binding file is valid bash syntax with single quotes" "0" "$?"

########################################################################################################################
echo "--- bind_last_macro ---"
########################################################################################################################

missing_file=$(mktemp)
rm -f "${missing_file}"
NIXLPER_LAST_MACRO_BINDING_FILE="${missing_file}"
bind_last_macro
_expect_eq "returns 1 when binding file is missing" "1" "$?"

# Restore to the temp file created at setup.
NIXLPER_LAST_MACRO_BINDING_FILE=$(mktemp)

########################################################################################################################
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
