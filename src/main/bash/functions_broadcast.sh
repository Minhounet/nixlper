#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_broadcast.sh
# DESCRIPTION: Admin broadcast message — a login notice any operator can register to warn the
# next people who log in (root or any account) about a change or workaround on the machine.
# Independent from nixlper's own welcome message/tips. Supports an optional auto-expiry so a
# temporary notice disappears on its own after N days, checked at login time.
########################################################################################################################

function _i_broadcast_message_file() {
  echo "${NIXLPER_BROADCAST_MESSAGE_FILE:-${NIXLPER_INSTALL_DIR}/broadcast_message}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_broadcast_active: returns 0 if a notice is registered and has not expired.
# A found-expired notice is deleted as a side effect, so it is only ever reported once.
#-----------------------------------------------------------------------------------------------------------------------
function _i_broadcast_active() {
  local -r file="$(_i_broadcast_message_file)"
  [[ -f "${file}" ]] || return 1

  local -r expiry_file="${file}.expires"
  if [[ -f "${expiry_file}" ]]; then
    local expiry
    expiry=$(cat "${expiry_file}" 2>/dev/null)
    if [[ "${expiry}" =~ ^[0-9]+$ ]] && (( $(date +%s) >= expiry )); then
      rm -f "${file}" "${expiry_file}"
      return 1
    fi
  fi
  return 0
}

function _i_print_broadcast_message() {
  local -r file="$(_i_broadcast_message_file)"
  echo "⚠️  ──────────────────────────── ADMIN NOTICE ────────────────────────────"
  cat "${file}"
  echo "────────────────────────────────────────────────────────────────────────"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_load_broadcast_message: called at login from _i_init. Silent when no notice is active.
#-----------------------------------------------------------------------------------------------------------------------
function _i_load_broadcast_message() {
  [[ "${NIXLPER_DISABLE_BROADCAST_MESSAGE:-false}" == "true" ]] && return
  _i_broadcast_active || return
  _i_print_broadcast_message
}

# @cmd-palette
# @description: Register an admin notice shown to everyone at next login
# @category: Admin
# @alias: bset
# @interactive
function set_broadcast_message() {
  local -r file="$(_i_broadcast_message_file)"

  echo -n "Message to broadcast at next login: "
  local message
  read -r message
  if [[ -z "${message}" ]]; then
    _i_log_as_error "Empty message, aborted."
    return 1
  fi

  echo -n "Expire in how many days? (blank = persistent until bclear): "
  local days
  read -r days

  if ! mkdir -p "$(dirname "${file}")" 2>/dev/null || ! printf '%s\n' "${message}" > "${file}" 2>/dev/null; then
    _i_log_as_error "Cannot write ${file} (permission denied?). Use sudo if this is a system-wide install."
    return 1
  fi

  local -r expiry_file="${file}.expires"
  rm -f "${expiry_file}"
  if [[ -n "${days}" ]]; then
    if [[ "${days}" =~ ^[0-9]+$ ]]; then
      date -d "+${days} days" +%s > "${expiry_file}"
      _i_log_as_info "Notice set, expires in ${days} day(s)."
    else
      _i_log_as_error "'${days}' is not a valid number of days, notice set as persistent instead."
    fi
  else
    _i_log_as_info "Notice set, persistent until bclear."
  fi
}

# @cmd-palette
# @description: Remove the current admin notice
# @category: Admin
# @alias: bclear
function clear_broadcast_message() {
  local -r file="$(_i_broadcast_message_file)"
  if [[ ! -f "${file}" ]]; then
    _i_log_as_info "No admin notice currently set."
    return 0
  fi
  if ! rm -f "${file}" "${file}.expires" 2>/dev/null; then
    _i_log_as_error "Cannot remove ${file} (permission denied?). Use sudo if this is a system-wide install."
    return 1
  fi
  _i_log_as_info "Admin notice cleared."
}

# @cmd-palette
# @description: Show the current admin notice on demand
# @category: Admin
# @alias: bshow
function show_broadcast_message() {
  if _i_broadcast_active; then
    _i_print_broadcast_message
  else
    _i_log_as_info "No admin notice currently set."
  fi
}
