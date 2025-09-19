#!/usr/bin/env bash
########################################################################################################################
# FILE: logging.sh
#  DESCRIPTION: Various logging functions
########################################################################################################################
function _i_log() {
  local -r category=$1
  local message=${@:2}
  local -r date=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${date} ${category} ${message}"
}
function _i_log_as_error() {
  _i_log "ERROR" $@
}
function _i_log_as_info() {
  _i_log "INFO" $@
}
function _i_log_action_cancelled() {
  _i_log_as_info "🔴Action is cancelled"
}
function _i_log_ok() {
  _i_log_as_info "👍"
}
