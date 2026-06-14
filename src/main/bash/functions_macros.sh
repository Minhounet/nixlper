#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_macros.sh
# DESCRIPTION: functions related to macros
########################################################################################################################
# CONTENT:
# - vim record like feature,
#   Use CTRL + P to start recording, CTRL + P + CTRL + P to stop recording
#   Use CTRL + X + CTRL + X to launch recorded actions
########################################################################################################################

_NIXLPER_RECORDING=false
_NIXLPER_MACRO_COMMANDS=()

# Thin wrapper so tests can mock the history lookup without touching the builtin.
function _i_get_last_cmd() {
  history 1 | sed 's/^ *[0-9]* *//'
}

# Injected into PROMPT_COMMAND during a recording session; fires after every command.
function _i_macro_record_step() {
  [[ "$_NIXLPER_RECORDING" != true ]] && return
  local last_cmd
  last_cmd=$(_i_get_last_cmd)
  case "$last_cmd" in
    sr|fr|start_recording|finalize_recording) return ;;
  esac
  [[ -n "$last_cmd" ]] && _NIXLPER_MACRO_COMMANDS+=("$last_cmd")
}

# @cmd-palette
# @description: Start recording bash commands
# @category: Macros
# @keybind: CTRL+P
# @alias: sr
function start_recording() {
  _NIXLPER_RECORDING=true
  _NIXLPER_MACRO_COMMANDS=()
  if [[ "$PROMPT_COMMAND" != *"_i_macro_record_step"* ]]; then
    PROMPT_COMMAND="_i_macro_record_step${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  fi
  _i_log_as_info "Recording started. Run your commands now."
}

# @cmd-palette
# @description: Stop and save macro recording
# @category: Macros
# @keybind: CTRL+P+CTRL+P
# @alias: fr
function finalize_recording() {
  _NIXLPER_RECORDING=false
  PROMPT_COMMAND="${PROMPT_COMMAND#_i_macro_record_step; }"
  PROMPT_COMMAND="${PROMPT_COMMAND%_i_macro_record_step}"
  _i_log_as_info "Recording stopped."
  _prepare_binding
}

function _prepare_binding() {
  if [[ ${#_NIXLPER_MACRO_COMMANDS[@]} -eq 0 ]]; then
    _i_log_as_info "No commands recorded."
    return 1
  fi

  local joined
  joined=$(printf '%s; ' "${_NIXLPER_MACRO_COMMANDS[@]}")
  joined="${joined%; }"

  bind -r "\C-x\C-x" 2>/dev/null
  local bind_command="bind -x '\"\\C-x\\C-x\":( $joined )'"
  eval "$bind_command" 2>/dev/null
  echo "$bind_command" > "$NIXLPER_LAST_MACRO_BINDING_FILE"
  _i_log_as_info "CTRL+X+CTRL+X bound to: $joined"
}

# @cmd-palette
# @description: Restore last macro binding — then press CTRL+X+CTRL+X to play
# @category: Macros
# @keybind: CTRL+P+CTRL+L
function bind_last_macro() {
  if [[ ! -f "$NIXLPER_LAST_MACRO_BINDING_FILE" ]]; then
    _i_log_as_error "Cannot bind last macro because nothing has been recorded"
    return 1
  fi
  _i_log_as_info "Launch last macro binding below:"
  cat "$NIXLPER_LAST_MACRO_BINDING_FILE"
  eval "$(cat "$NIXLPER_LAST_MACRO_BINDING_FILE")" 2>/dev/null
  _i_log_ok
}
