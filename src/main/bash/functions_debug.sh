#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_debug.sh
# DESCRIPTION: Debug mode — toggle NIXLPER_DEBUG and trace individual nixlper functions.
#
# Non-obvious mechanism: _nixlper_debug_exec wraps a function call in set -x / set +x so only
# that function's execution is traced, avoiding the flood that global set -x causes in an
# interactive shell (readline, PROMPT_COMMAND, etc. would all appear in the trace).
# See INTERNALS.md for details.
########################################################################################################################

# @cmd-palette
# @description: Toggle nixlper debug mode on/off (shows config summary when enabled)
# @category: Debug
# @keybind: CTRL+X+Z
function nixlper_debug_toggle() {
  if [[ "${NIXLPER_DEBUG:-false}" == "true" ]]; then
    export NIXLPER_DEBUG=false
    echo "[NIXLPER DEBUG] Debug mode disabled."
  else
    export NIXLPER_DEBUG=true
    echo "[NIXLPER DEBUG] Debug mode enabled."
    _nixlper_debug_show_config
  fi
}

# @cmd-palette
# @description: Trace a single nixlper function call with set -x (usage: ndebug <function> [args])
# @category: Debug
# @alias: ndebug
# @args: FUNCTION [ARGS...]
function nixlper_debug_exec() {
  if [[ $# -eq 0 ]]; then
    echo "[NIXLPER DEBUG] Usage: ndebug <function> [args...]"
    echo "  Example: ndebug navigate"
    echo "  Example: ndebug _check_update"
    return 1
  fi

  local func="$1"; shift

  if ! declare -f "$func" >/dev/null 2>&1; then
    echo "[NIXLPER DEBUG] Function not found: $func"
    echo "  Tip: run 'declare -F | grep nixlper' to list loaded functions."
    return 1
  fi

  echo "[NIXLPER DEBUG] Tracing: $func $*"
  echo "──────────────────────────────────────────────────────────"
  { set -x; "$func" "$@"; } 2>&1
  local exit_code=$?
  { set +x; } 2>/dev/null
  echo "──────────────────────────────────────────────────────────"
  echo "[NIXLPER DEBUG] Exit code: $exit_code"
  return $exit_code
}

# @cmd-palette
# @description: Show resolved values of all NIXLPER_* variables
# @category: Debug
# @alias: ndbconf
function nixlper_debug_show_config() {
  _nixlper_debug_show_config
}

#-----------------------------------------------------------------------------------------------------------------------
# Internal helpers
#-----------------------------------------------------------------------------------------------------------------------
function _nixlper_debug_show_config() {
  echo ""
  echo "──────────────────────────────────────────────────────────"
  echo "  [NIXLPER DEBUG] Resolved configuration"
  echo "──────────────────────────────────────────────────────────"
  printf "  %-40s %s\n" "NIXLPER_DEBUG"                  "${NIXLPER_DEBUG:-false}"
  printf "  %-40s %s\n" "NIXLPER_INSTALL_DIR"            "${NIXLPER_INSTALL_DIR:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_EDITOR"                 "${NIXLPER_EDITOR:-vim}"
  printf "  %-40s %s\n" "NIXLPER_NAVIGATE_MODE"          "${NIXLPER_NAVIGATE_MODE:-tree}"
  printf "  %-40s %s\n" "NIXLPER_BOOKMARKS_FILE"         "${NIXLPER_BOOKMARKS_FILE:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_SNAPSHOT_DIR"           "${NIXLPER_SNAPSHOT_DIR:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_CUSTOM_DIR"             "${NIXLPER_CUSTOM_DIR:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_DISABLE_WELCOME_MESSAGE" "${NIXLPER_DISABLE_WELCOME_MESSAGE:-false}"
  printf "  %-40s %s\n" "NIXLPER_DISABLE_TIPS"           "${NIXLPER_DISABLE_TIPS:-false}"
  printf "  %-40s %s\n" "NIXLPER_JOKE_LANG"              "${NIXLPER_JOKE_LANG:-auto}"
  printf "  %-40s %s\n" "NIXLPER_UPDATE_CHANNEL"         "${NIXLPER_UPDATE_CHANNEL:-stable}"
  printf "  %-40s %s\n" "NIXLPER_UPDATE_CHECK"           "${NIXLPER_UPDATE_CHECK:-true}"
  printf "  %-40s %s\n" "NIXLPER_UPDATE_AUTO"            "${NIXLPER_UPDATE_AUTO:-false}"
  printf "  %-40s %s\n" "NIXLPER_UPDATE_CHECK_INTERVAL"  "${NIXLPER_UPDATE_CHECK_INTERVAL:-86400}"
  printf "  %-40s %s\n" "NIXLPER_UPDATE_TIMEOUT"         "${NIXLPER_UPDATE_TIMEOUT:-2}"
  printf "  %-40s %s\n" "NIXLPER_UPDATE_CACHE_FILE"      "${NIXLPER_UPDATE_CACHE_FILE:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_RECENT_DIRS_MAX"        "${NIXLPER_RECENT_DIRS_MAX:-20}"
  printf "  %-40s %s\n" "NIXLPER_RECENT_DIRS_FILE"       "${NIXLPER_RECENT_DIRS_FILE:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_TARGET_DIR"             "${NIXLPER_TARGET_DIR:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_LAST_MACRO_BINDING_FILE" "${NIXLPER_LAST_MACRO_BINDING_FILE:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_SSH_CONNECTIONS_FILE"   "${NIXLPER_SSH_CONNECTIONS_FILE:-(unset)}"
  printf "  %-40s %s\n" "NIXLPER_SSH_IDENTITY_FILE"      "${NIXLPER_SSH_IDENTITY_FILE:-(unset)}"
  echo "──────────────────────────────────────────────────────────"
  echo ""
}
