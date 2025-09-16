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

  # 🔥We decided to join all command with ";" to avoid return line issues. 
  local joined
  joined=$(echo "$commands" | paste -sd ';' -)

  bind -x "\"\C-x\C-x\":( $joined )"

  _i_log_as_info "Ctrl+x Ctrl+x bound to your recorded commands."
}
