#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_sound.sh
# DESCRIPTION: Offline unit tests for the sound feature (functions_sound.sh).
#
# Pure bash, no external framework, no real audio: `beep` and `command -v` are overridden with
# mocks so the suite never actually touches a PC speaker and runs deterministically in CI.
# Run locally with:  bash src/test/bash/test_functions_sound.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_sound.sh"
LOGGING="${REPO_ROOT}/src/main/bash/functions_logging.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${LOGGING}"
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

_expect_match_count() {  # $1 name, $2 haystack, $3 regex, $4 expected count
  local -r name="$1" haystack="$2" regex="$3" want="$4"
  local got
  got="$(printf '%s\n' "${haystack}" | grep -c -E "${regex}")"
  _expect_eq "${name}" "${got}" "${want}"
}

#-----------------------------------------------------------------------------------------------------------------------
echo "== alias registration (regression) =="
# `@alias: tune` in functions_sound.sh only tells the palette what name to display — it does NOT
# create the shell alias itself. Without `alias tune=_play_tune` in nixlper.sh's ALIASES section,
# `tune [PRESET]` (the form every doc page advertises) fails with "command not found" even though
# `_play_tune` works. Guard against that regressing silently.
NIXLPER_SH="${REPO_ROOT}/src/main/bash/nixlper.sh"
_expect_match_count "nixlper.sh registers the tune alias" "$(cat "${NIXLPER_SH}")" "^alias tune=_play_tune$" 1

echo "== _i_sound_preset_notes =="
_expect_eq "success preset resolves"      "$(_i_sound_preset_notes success)" "${_NIXLPER_SOUND_PRESET_SUCCESS}"
_expect_eq "error preset resolves"        "$(_i_sound_preset_notes error)"   "${_NIXLPER_SOUND_PRESET_ERROR}"
_expect_eq "fanfare preset resolves"      "$(_i_sound_preset_notes fanfare)" "${_NIXLPER_SOUND_PRESET_FANFARE}"
_i_sound_preset_notes bogus >/dev/null 2>&1
_expect_eq "unknown preset: return 1" "$?" "1"

echo "== _i_sound_beep_args =="
out="$(_i_sound_beep_args "523:120 659:220")"
_expect_eq "single-note-separator omitted, two notes joined with -n" "${out}" "$(printf '%s\n' -f 523 -l 120 -n -f 659 -l 220)"

echo "== _play_tune: unknown preset =="
out="$(_play_tune bogus 2>&1)"; rc=$?
_expect_match_count "unknown preset: error message" "${out}" "Unknown preset 'bogus'" 1
_expect_eq "unknown preset: return 1" "${rc}" "1"

echo "== _play_tune: beep missing =="
command() {  # shadow the builtin just for `command -v beep`
  if [[ "$1" == "-v" && "$2" == "beep" ]]; then return 1; fi
  builtin command "$@"
}
out="$(_play_tune 2>&1)"; rc=$?
_expect_match_count "beep missing: error message" "${out}" "'beep' is not installed" 1
_expect_eq "beep missing: return 1" "${rc}" "1"
unset -f command

echo "== _play_tune: beep present, default preset =="
command() {
  if [[ "$1" == "-v" && "$2" == "beep" ]]; then return 0; fi
  builtin command "$@"
}
BEEP_ARGS_FILE="$(mktemp)"
trap 'rm -f "${BEEP_ARGS_FILE}"' EXIT
beep() { printf '%s\n' "$@" > "${BEEP_ARGS_FILE}"; return 0; }
unset NIXLPER_SOUND_DEFAULT_PRESET
_play_tune >/dev/null 2>&1; rc=$?
_expect_eq "beep present: return 0" "${rc}" "0"
_expect_eq "default preset used when no arg" "$(cat "${BEEP_ARGS_FILE}")" "$(_i_sound_beep_args "${_NIXLPER_SOUND_PRESET_SUCCESS}")"

echo "== _play_tune: NIXLPER_SOUND_DEFAULT_PRESET honoured =="
export NIXLPER_SOUND_DEFAULT_PRESET=error
_play_tune >/dev/null 2>&1
_expect_eq "configured default preset used" "$(cat "${BEEP_ARGS_FILE}")" "$(_i_sound_beep_args "${_NIXLPER_SOUND_PRESET_ERROR}")"
unset NIXLPER_SOUND_DEFAULT_PRESET

echo "== _play_tune: explicit arg overrides default =="
_play_tune fanfare >/dev/null 2>&1
_expect_eq "explicit preset used" "$(cat "${BEEP_ARGS_FILE}")" "$(_i_sound_beep_args "${_NIXLPER_SOUND_PRESET_FANFARE}")"
unset -f command beep

echo "== _play_tune: beep present but fails (no speaker access) =="
command() {
  if [[ "$1" == "-v" && "$2" == "beep" ]]; then return 0; fi
  builtin command "$@"
}
beep() { return 1; }
out="$(_play_tune 2>&1)"; rc=$?
_expect_match_count "beep failure: error message" "${out}" "beep could not play" 1
_expect_eq "beep failure: return 1" "${rc}" "1"
unset -f command beep

#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "====================================================================================================="
echo "RESULT: ${PASS} passed, ${FAIL} failed"
echo "====================================================================================================="
[[ ${FAIL} -eq 0 ]]
