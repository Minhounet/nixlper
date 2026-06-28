#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_recent_dirs.sh
# DESCRIPTION: Track and navigate recently visited directories (frecency-lite — recency only)
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _i_recent_dirs_file: resolve the recent dirs history file path
#-----------------------------------------------------------------------------------------------------------------------
function _i_recent_dirs_file() {
  echo "${NIXLPER_RECENT_DIRS_FILE:-${HOME}/.local/share/nixlper/recent_dirs}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_recent_dirs_track: appended to PROMPT_COMMAND; fires after every interactive command.
# Records $PWD into the history file, deduplicates, and caps at NIXLPER_RECENT_DIRS_MAX entries.
# Home and root are skipped — they are too generic to be useful in a recency list.
#-----------------------------------------------------------------------------------------------------------------------
function _i_recent_dirs_track() {
  local -r current="$PWD"
  [[ "$current" == "$HOME" || "$current" == "/" ]] && return 0

  local -r file=$(_i_recent_dirs_file)
  local -r max="${NIXLPER_RECENT_DIRS_MAX:-20}"

  mkdir -p "$(dirname "$file")"

  local tmp
  tmp=$(mktemp)
  # Prepend current dir; remove any prior occurrence; trim to max
  { echo "$current"; grep -vxF "$current" "$file" 2>/dev/null || true; } | head -n "$max" > "$tmp"
  mv "$tmp" "$file"
}

#-----------------------------------------------------------------------------------------------------------------------
# recent_dirs: interactive numbered picker for recently visited directories
# @cmd-palette
# @description: Navigate to a recently visited directory (numbered picker)
# @category: Navigation
# @keybind: CTRL+X+J
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function recent_dirs() {
  local -r file=$(_i_recent_dirs_file)

  if [[ ! -f "$file" ]] || [[ ! -s "$file" ]]; then
    _i_log_as_info "No recent directories yet — navigate to a few folders first."
    return 0
  fi

  local -a dirs=()
  while IFS= read -r line; do
    [[ -d "$line" ]] && dirs+=("$line")
  done < "$file"

  if [[ ${#dirs[@]} -eq 0 ]]; then
    _i_log_as_info "No recent directories available (all recorded paths have been removed)."
    return 0
  fi

  echo ""
  _i_log_as_info "Recent directories (most recent first):"
  local i=1
  for dir in "${dirs[@]}"; do
    printf "  %2d) %s\n" "$i" "$dir"
    ((i++))
  done
  echo ""

  local choice
  read -rp "Jump to [1-${#dirs[@]}] (Enter to cancel): " choice

  [[ -z "$choice" ]] && _i_log_as_info "Cancelled." && return 0

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#dirs[@]} )); then
    _i_log_as_error "Invalid selection: $choice"
    return 1
  fi

  local -r target="${dirs[$((choice - 1))]}"
  if [[ ! -d "$target" ]]; then
    _i_log_as_error "Directory no longer exists: $target"
    return 1
  fi

  cd "$target" && _i_log_as_info "Jumped to $target"
}

alias rd='recent_dirs'

#-----------------------------------------------------------------------------------------------------------------------
# _i_recent_dirs_init: hook _i_recent_dirs_track into PROMPT_COMMAND (called once at startup)
#-----------------------------------------------------------------------------------------------------------------------
function _i_recent_dirs_init() {
  local existing="${PROMPT_COMMAND:-}"
  if [[ "$existing" != *"_i_recent_dirs_track"* ]]; then
    PROMPT_COMMAND="_i_recent_dirs_track${existing:+; $existing}"
  fi
}
