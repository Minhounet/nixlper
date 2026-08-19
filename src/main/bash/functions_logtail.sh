#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_logtail.sh
# DESCRIPTION: Follow a log file, highlighting lines that match a pattern
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _i_logtail_grep_flags: echo the grep flags to use, honouring NIXLPER_LOGTAIL_IGNORE_CASE
#-----------------------------------------------------------------------------------------------------------------------
function _i_logtail_grep_flags() {
  local flags="--color=always --line-buffered -E"
  [[ "${NIXLPER_LOGTAIL_IGNORE_CASE:-false}" == "true" ]] && flags="${flags} -i"
  echo "${flags}"
}

# @cmd-palette
# @description: Follow a log file, highlighting lines matching a pattern
# @category: Logs
# @alias: logtail
# @args: FILE PATTERN
function _logtail() {
  if [[ $# -lt 2 ]]; then
    _i_log_as_error "$0: Usage: logtail FILE PATTERN"
    return 1
  fi
  local -r file="$1"
  local -r pattern="$2"

  if [[ ! -f "${file}" ]]; then
    _i_log_as_error "$0: File not found: ${file}"
    return 1
  fi

  local -a grep_flags
  read -ra grep_flags <<< "$(_i_logtail_grep_flags)"

  _i_log_as_info "Following ${file}, highlighting matches for '${pattern}' (CTRL+C to stop)"
  tail -n "${NIXLPER_LOGTAIL_LINES:-10}" -F -- "${file}" | grep "${grep_flags[@]}" -- "${pattern}"
}
