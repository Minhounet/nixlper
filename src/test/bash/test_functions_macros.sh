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
start_recording
_expect_eq "sets _NIXLPER_RECORDING=true" "true" "${_NIXLPER_RECORDING}"

PROMPT_COMMAND=""
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
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "does nothing when not recording" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"

_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_i_get_last_cmd() { echo "ls -la"; }
_i_macro_record_step
_expect_eq "appends regular command" "1" "${#_NIXLPER_MACRO_COMMANDS[@]}"
_expect_eq "captures correct command text" "ls -la" "${_NIXLPER_MACRO_COMMANDS[0]}"

_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
_i_get_last_cmd() { echo ""; }
_i_macro_record_step
_expect_eq "ignores empty command" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"

for skip_cmd in sr fr start_recording finalize_recording; do
  _NIXLPER_RECORDING=true
  _NIXLPER_MACRO_COMMANDS=()
  _i_get_last_cmd() { echo "${skip_cmd}"; }
  _i_macro_record_step
  _expect_eq "skips '${skip_cmd}'" "0" "${#_NIXLPER_MACRO_COMMANDS[@]}"
done

_NIXLPER_RECORDING=true
_NIXLPER_MACRO_COMMANDS=()
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
_expect_contains "writes binding file" "${file_content}" "ls -la; cd /tmp"

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
