#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_macros.sh
# DESCRIPTION: functions related to macros
########################################################################################################################
# CONTENT:
# - vim record like feature, 
#   Use CTRL + X, CTRL + Q to start recording, CTRL + Q to stop recording
#   Use CTRL + X, CTRL + X to launch recorded actions
########################################################################################################################
START_MARKER="###START_RECORD###"
END_MARKER="###END_RECORD###"

function start_recording() {
  history -s "$START_MARKER"
  history -a
  _i_log_as_info "Recording started. Run your commands now."
}

function finalize_recording() {
  _stop_record
  _clean_markers
}

function _stop_record() {
  history -s "$END_MARKER"
  history -a
  _i_log_as_info "Recording stopped."
  _prepare_binding
}

function _extract_record() {
  # Make sure history is saved to file
  history -a

  sed -n "/$START_MARKER/,/$END_MARKER/p" ~/.bash_history | sed "1d;\$d"
}

function _clean_markers() {
  for marker in "$START_MARKER" "$END_MARKER"; do
    while read -r lineno _; do
      history -d "$lineno"
    done < <(history | grep -F "$marker" | awk '{print $1}')
  done
  sed -i "/$START_MARKER/d;/$END_MARKER/d" ~/.bash_history
  history -c
  history -r
}

function _prepare_binding() {
  local commands
  commands=$(_extract_record)

  if [ -z "$commands" ]; then
    _i_log_as_info "No commands recorded between markers."
    return 1
  fi

  bind -r "\C-x\C-x" 2>/dev/null

  # Join all commands with ';' to avoid new line issues
  local joined
  joined=$(echo "$commands" | paste -sd ';' -)

  # The bind command string
  local bind_command="bind -x '\"\\C-x\\C-x\":( $joined )'"

  # Bind it in the current shell
  eval "$bind_command"
  
  # Save it to a file for later replay
  echo "$bind_command" > "$NIXLPER_LAST_MACRO_BINDING_FILE"

  _i_log_as_info "Ctrl+x Ctrl+x bound to your recorded commands and saved to $NIXLPER_LAST_MACRO_BINDING_FILE"
}

function bind_last_macro() {
  if [[ ! -f "$NIXLPER_LAST_MACRO_BINDING_FILE" ]]; then
    _i_log_as_error "Cannot bind last macro because nothing has been recorded"
  fi
  _i_log_as_info "Launch last macro binding below:"
  cat "$NIXLPER_LAST_MACRO_BINDING_FILE"
  eval $(cat "$NIXLPER_LAST_MACRO_BINDING_FILE")
  _i_log_ok
}
