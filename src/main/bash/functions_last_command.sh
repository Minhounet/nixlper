#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_last_command.sh
# DESCRIPTION: Re-run a previous shell command, picked via fuzzy search or a numbered list
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _i_last_command_history_raw: bash's own history list, most recent entry first, one command per
# line with the leading "NUM  " index stripped. HISTTIMEFORMAT is neutralised locally (shadowed
# for the lifetime of this function) so a configured timestamp never leaks into the command text.
#-----------------------------------------------------------------------------------------------------------------------
function _i_last_command_history_raw() {
  local HISTTIMEFORMAT=''
  builtin history | tac | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//'
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_last_command_list: deduplicated command history (most recent occurrence wins, blank lines
# and self-invocations of this feature skipped), capped at NIXLPER_LAST_COMMAND_MAX.
#-----------------------------------------------------------------------------------------------------------------------
function _i_last_command_list() {
  local -r max="${NIXLPER_LAST_COMMAND_MAX:-50}"
  local -A seen=()
  local -a result=()
  local line

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" == "lc" || "$line" == "last_command" ]] && continue
    [[ -n "${seen[$line]:-}" ]] && continue
    seen["$line"]=1
    result+=("$line")
    (( ${#result[@]} >= max )) && break
  done < <(_i_last_command_history_raw)

  ((${#result[@]} == 0)) && return 0
  printf '%s\n' "${result[@]}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_last_command_indexed_list: print deduplicated history entries prefixed with their 1-based
# index ("N  command"), one per line — same number-jump/fuzzy-filter trick used by recent_dirs.
#-----------------------------------------------------------------------------------------------------------------------
function _i_last_command_indexed_list() {
  local i=1
  local line
  while IFS= read -r line; do
    printf '%d  %s\n' "$i" "$line"
    ((i++))
  done < <(_i_last_command_list)
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_last_command_confirm_and_run: preload the chosen command onto an editable prompt (safety
# pattern: display the command before execution) so it can be reviewed, tweaked, or cancelled.
# Pressing Enter as-is runs it unchanged; clearing the line cancels.
#-----------------------------------------------------------------------------------------------------------------------
function _i_last_command_confirm_and_run() {
  local -r cmd="$1"
  local edited

  read -re -i "$cmd" -p "Run> " edited

  if [[ -z "$edited" ]]; then
    _i_log_as_info "Cancelled."
    return 0
  fi

  history -s "$edited"
  eval "$edited"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_last_command_fuzzy_pick: fzf-backed incremental filter — type digits to jump to that
# numbered entry, or letters to fuzzy-filter the command text live — used when fzf is available.
#-----------------------------------------------------------------------------------------------------------------------
function _i_last_command_fuzzy_pick() {
  local selected
  selected=$(_i_last_command_indexed_list | fzf \
    --prompt="Last commands > " \
    --height=40% \
    --reverse \
    --header="Type a number to jump, or letters to fuzzy-filter | ENTER: select | ESC: cancel")

  [[ -z "$selected" ]] && _i_log_as_info "Cancelled." && return 0

  # Strip the "N  " index prefix — safe unconditionally, same reasoning as recent_dirs: the
  # first "  " (two spaces) in the line is always our separator, never part of the command text.
  local -r target="${selected#*  }"
  _i_last_command_confirm_and_run "$target"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_last_command_numbered_pick: classic numbered picker — used when fzf is not installed, or
# NIXLPER_LAST_COMMAND_FUZZY is set to false.
#-----------------------------------------------------------------------------------------------------------------------
function _i_last_command_numbered_pick() {
  local -a cmds=()
  local line
  while IFS= read -r line; do
    cmds+=("$line")
  done < <(_i_last_command_list)

  echo ""
  _i_log_as_info "Command history (most recent first):"
  local i=1
  for c in "${cmds[@]}"; do
    printf "  %2d) %s\n" "$i" "$c"
    ((i++))
  done
  echo ""

  local choice
  read -rp "Select [1-${#cmds[@]}] (Enter to cancel): " choice

  [[ -z "$choice" ]] && _i_log_as_info "Cancelled." && return 0

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#cmds[@]} )); then
    _i_log_as_error "Invalid selection: $choice"
    return 1
  fi

  _i_last_command_confirm_and_run "${cmds[$((choice - 1))]}"
}

#-----------------------------------------------------------------------------------------------------------------------
# last_command: re-run a previous shell command. Opens an fzf incremental filter when fzf is
# installed and NIXLPER_LAST_COMMAND_FUZZY is not disabled — type digits to jump to that numbered
# entry, or letters to fuzzy-filter the command text live. Falls back to the classic numbered
# picker when fzf is unavailable or fuzzy mode is disabled. Either way, the chosen command is
# preloaded onto an editable prompt rather than run blindly, so it can be reviewed first.
# @cmd-palette
# @description: Re-run a previous command (number-jump or fuzzy search via fzf)
# @category: History
# @keybind: CTRL+X+L
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function last_command() {
  if [[ -z "$(_i_last_command_list)" ]]; then
    _i_log_as_info "No command history available yet."
    return 0
  fi

  if [[ "${NIXLPER_LAST_COMMAND_FUZZY:-true}" == "true" ]] && command -v fzf &>/dev/null; then
    _i_last_command_fuzzy_pick
  else
    _i_last_command_numbered_pick
  fi
}

alias lc='last_command'
