#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_sound.sh
# DESCRIPTION: Play a short pitched tune through the PC speaker via the 'beep' utility
########################################################################################################################

# Preset tunes: space-separated "FREQ_HZ:LENGTH_MS" note pairs.
_NIXLPER_SOUND_PRESET_SUCCESS="523:120 659:120 784:120 1047:220"
_NIXLPER_SOUND_PRESET_ERROR="392:200 262:350"
_NIXLPER_SOUND_PRESET_FANFARE="784:100 784:100 784:100 1047:350"

#-----------------------------------------------------------------------------------------------------------------------
# _i_sound_preset_notes: echo the note sequence for a preset name, or return 1 if unknown
#-----------------------------------------------------------------------------------------------------------------------
function _i_sound_preset_notes() {
  case "$1" in
    success) echo "${_NIXLPER_SOUND_PRESET_SUCCESS}" ;;
    error) echo "${_NIXLPER_SOUND_PRESET_ERROR}" ;;
    fanfare) echo "${_NIXLPER_SOUND_PRESET_FANFARE}" ;;
    *) return 1 ;;
  esac
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_sound_beep_args: turn a "FREQ:LEN ..." note sequence into beep(1) argv, one arg per line
#-----------------------------------------------------------------------------------------------------------------------
function _i_sound_beep_args() {
  local -r notes="$1"
  local note freq length first=true
  for note in ${notes}; do
    freq="${note%%:*}"
    length="${note##*:}"
    # printf, not echo: echo "-n" is swallowed as the no-trailing-newline flag rather than
    # printed literally, silently dropping the note separator beep(1) needs.
    [[ "${first}" == "true" ]] || printf '%s\n' "-n"
    printf '%s\n' "-f" "${freq}" "-l" "${length}"
    first=false
  done
}

# @cmd-palette
# @description: Play a short pitched tune through the PC speaker (requires the 'beep' package; local machine only, not heard over SSH)
# @category: Sound
# @alias: tune
# @args: [PRESET]
function _play_tune() {
  local -r preset="${1:-${NIXLPER_SOUND_DEFAULT_PRESET:-success}}"

  local notes
  if ! notes="$(_i_sound_preset_notes "${preset}")"; then
    _i_log_as_error "$0: Unknown preset '${preset}'. Available: success, error, fanfare."
    return 1
  fi

  if ! command -v beep &>/dev/null; then
    _i_log_as_error "$0: 'beep' is not installed (e.g. 'sudo apt install beep' / 'sudo dnf install beep'). It only sounds on the local PC speaker, not over SSH."
    return 1
  fi

  local -a beep_args
  readarray -t beep_args < <(_i_sound_beep_args "${notes}")

  if ! beep "${beep_args[@]}" 2>/dev/null; then
    _i_log_as_error "$0: beep could not play (no PC speaker access here). Check the pcspkr kernel module is loaded and you have permission to write to the console/evdev device, or run with sudo."
    return 1
  fi
}
