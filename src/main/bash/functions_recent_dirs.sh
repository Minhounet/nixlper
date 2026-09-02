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
# _i_recent_dirs_list: print recorded directories that still exist on disk, one per line
#-----------------------------------------------------------------------------------------------------------------------
function _i_recent_dirs_list() {
  local -r file="$1"
  while IFS= read -r line; do
    [[ -d "$line" ]] && echo "$line"
  done < "$file"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_recent_dirs_fuzzy_pick: fzf-backed incremental fuzzy filter (type a few chars to narrow the
# list live, arrows to move, Enter to jump, Esc to cancel) — used when fzf is available.
#-----------------------------------------------------------------------------------------------------------------------
function _i_recent_dirs_fuzzy_pick() {
  local -r file="$1"

  local selected
  selected=$(_i_recent_dirs_list "$file" | fzf \
    --prompt="Recent dirs > " \
    --height=40% \
    --reverse \
    --header="Type to fuzzy-filter | ENTER: jump | ESC: cancel")

  [[ -z "$selected" ]] && _i_log_as_info "Cancelled." && return 0

  if [[ ! -d "$selected" ]]; then
    _i_log_as_error "Directory no longer exists: $selected"
    return 1
  fi

  cd "$selected" && _i_log_as_info "Jumped to $selected"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_recent_dirs_numbered_pick: classic numbered picker — used when fzf is not installed, or
# NIXLPER_RECENT_DIRS_FUZZY is set to false.
#-----------------------------------------------------------------------------------------------------------------------
function _i_recent_dirs_numbered_pick() {
  local -r file="$1"

  local -a dirs=()
  while IFS= read -r line; do
    dirs+=("$line")
  done < <(_i_recent_dirs_list "$file")

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

#-----------------------------------------------------------------------------------------------------------------------
# recent_dirs: navigate to a recently visited directory.
# Opens an fzf incremental fuzzy filter when fzf is installed and NIXLPER_RECENT_DIRS_FUZZY is
# not disabled (type a few characters to narrow the list live, like IntelliJ's "recent files").
# Falls back to the classic numbered picker when fzf is unavailable or fuzzy mode is disabled.
# @cmd-palette
# @description: Navigate to a recently visited directory (fuzzy search when fzf is available)
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

  if [[ -z "$(_i_recent_dirs_list "$file")" ]]; then
    _i_log_as_info "No recent directories available (all recorded paths have been removed)."
    return 0
  fi

  if [[ "${NIXLPER_RECENT_DIRS_FUZZY:-true}" == "true" ]] && command -v fzf &>/dev/null; then
    _i_recent_dirs_fuzzy_pick "$file"
  else
    _i_recent_dirs_numbered_pick "$file"
  fi
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
