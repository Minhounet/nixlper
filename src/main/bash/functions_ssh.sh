#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_ssh.sh
# DESCRIPTION: SSH connection manager — quick pick, auto ssh-copy-id on first use
########################################################################################################################

# Connection file: label|user|host|port|identity_file  (one per line, # = comment)
_NIXLPER_SSH_CONNECTIONS_FILE="${NIXLPER_SSH_CONNECTIONS_FILE:-${HOME}/.config/nixlper/ssh_connections}"
_NIXLPER_SSH_IDENTITY_FILE="${NIXLPER_SSH_IDENTITY_FILE:-${HOME}/.ssh/nixlper_id_rsa}"

#-----------------------------------------------------------------------------------------------------------------------
# _i_ssh_ensure_key: generate the nixlper SSH keypair if it does not exist yet
#-----------------------------------------------------------------------------------------------------------------------
function _i_ssh_ensure_key() {
  local -r key="${_NIXLPER_SSH_IDENTITY_FILE}"
  if [[ ! -f "${key}" ]]; then
    echo "No nixlper SSH key found — generating ${key} ..."
    ssh-keygen -t rsa -b 4096 -f "${key}" -N "" -C "nixlper@$(hostname)" 2>&1
    echo "Key generated."
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_ssh_key_auth_works: return 0 if key-based login succeeds (no password needed), 1 otherwise
# Uses BatchMode so it never hangs waiting for a password
#-----------------------------------------------------------------------------------------------------------------------
function _i_ssh_key_auth_works() {
  local -r user="$1" host="$2" port="$3" key="$4"
  ssh -o BatchMode=yes \
      -o ConnectTimeout=5 \
      -o StrictHostKeyChecking=accept-new \
      -i "${key}" \
      -p "${port}" \
      "${user}@${host}" \
      exit 2>/dev/null
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_ssh_push_key: run ssh-copy-id interactively (user types password once)
#-----------------------------------------------------------------------------------------------------------------------
function _i_ssh_push_key() {
  local -r user="$1" host="$2" port="$3" key="$4"
  echo "First connection to ${user}@${host}:${port} — pushing SSH key (you will be asked for your password once)."
  ssh-copy-id -i "${key}.pub" -p "${port}" "${user}@${host}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_ssh_connect: ensure key auth then open the connection
#-----------------------------------------------------------------------------------------------------------------------
function _i_ssh_connect() {
  local -r label="$1" user="$2" host="$3" port="$4" key="$5"
  _i_ssh_ensure_key
  if ! _i_ssh_key_auth_works "${user}" "${host}" "${port}" "${key}"; then
    _i_ssh_push_key "${user}" "${host}" "${port}" "${key}" || {
      _i_log_as_error "ssh-copy-id failed — aborting."
      return 1
    }
  fi
  echo "Connecting to ${label} (${user}@${host}:${port}) ..."
  ssh -i "${key}" -p "${port}" "${user}@${host}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_ssh_load_connections: print valid (non-blank, non-comment) lines from the connections file
#-----------------------------------------------------------------------------------------------------------------------
function _i_ssh_load_connections() {
  local -r file="${_NIXLPER_SSH_CONNECTIONS_FILE}"
  [[ -f "${file}" ]] && grep -v '^\s*#' "${file}" | grep -v '^\s*$'
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_ssh_parse_field: extract field N (1-based) from a pipe-delimited connection line
#-----------------------------------------------------------------------------------------------------------------------
function _i_ssh_parse_field() {
  echo "$1" | cut -d'|' -f"$2"
}

#-----------------------------------------------------------------------------------------------------------------------
# sc: SSH Connect — fzf picker then connect
#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: SSH connect — pick a saved connection and open it
# @category: SSH
# @keybind: CTRL+X+S
# @interactive
function sc() {
  if ! command -v fzf &>/dev/null; then
    _i_log_as_error "fzf is required for the SSH connection picker."
    return 1
  fi

  local connections
  connections=$(_i_ssh_load_connections)
  if [[ -z "${connections}" ]]; then
    _i_log_as_info "No SSH connections saved. Use 'sca' to add one."
    return 0
  fi

  # Build display lines: "label  user@host:port"
  local display_lines=""
  while IFS= read -r line; do
    local lbl user host port
    lbl=$(_i_ssh_parse_field "${line}" 1)
    user=$(_i_ssh_parse_field "${line}" 2)
    host=$(_i_ssh_parse_field "${line}" 3)
    port=$(_i_ssh_parse_field "${line}" 4)
    display_lines+="${lbl}  ${user}@${host}:${port}"$'\n'
  done <<< "${connections}"

  local selected_label
  selected_label=$(printf '%s' "${display_lines}" | fzf --prompt="SSH > " --height=40% --reverse | awk '{print $1}')
  [[ -z "${selected_label}" ]] && return 0

  # Find matching connection line
  local conn_line
  conn_line=$(echo "${connections}" | grep "^${selected_label}|")
  if [[ -z "${conn_line}" ]]; then
    _i_log_as_error "Connection '${selected_label}' not found."
    return 1
  fi

  local lbl user host port key
  lbl=$(_i_ssh_parse_field "${conn_line}" 1)
  user=$(_i_ssh_parse_field "${conn_line}" 2)
  host=$(_i_ssh_parse_field "${conn_line}" 3)
  port=$(_i_ssh_parse_field "${conn_line}" 4)
  key=$(_i_ssh_parse_field "${conn_line}" 5)
  key="${key:-${_NIXLPER_SSH_IDENTITY_FILE}}"

  _i_ssh_connect "${lbl}" "${user}" "${host}" "${port}" "${key}"
}

#-----------------------------------------------------------------------------------------------------------------------
# sca: SSH Connection Add — add a new connection interactively
#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: Add a new SSH connection profile
# @category: SSH
# @alias: sca
# @interactive
function sca() {
  local file="${_NIXLPER_SSH_CONNECTIONS_FILE}"
  mkdir -p "$(dirname "${file}")"

  echo "── Add SSH Connection ──────────────────────────────────────────────────────"
  read -rp "Label (short name, no spaces): " label
  [[ -z "${label}" ]] && { _i_log_as_error "Label cannot be empty."; return 1; }

  # Reject duplicate labels
  if _i_ssh_load_connections | grep -q "^${label}|"; then
    _i_log_as_error "A connection named '${label}' already exists. Use 'scr' to remove it first."
    return 1
  fi

  read -rp "User: " user
  [[ -z "${user}" ]] && { _i_log_as_error "User cannot be empty."; return 1; }

  read -rp "Host: " host
  [[ -z "${host}" ]] && { _i_log_as_error "Host cannot be empty."; return 1; }

  read -rp "Port (default 22): " port
  port="${port:-22}"

  read -rp "Identity file (default: ${_NIXLPER_SSH_IDENTITY_FILE}): " key
  key="${key:-}"   # empty = use global default at connect time

  echo "${label}|${user}|${host}|${port}|${key}" >> "${file}"
  _i_log_as_info "Connection '${label}' saved."
}

#-----------------------------------------------------------------------------------------------------------------------
# scr: SSH Connection Remove — remove a connection by label
#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: Remove a saved SSH connection profile
# @category: SSH
# @alias: scr
# @interactive
function scr() {
  if ! command -v fzf &>/dev/null; then
    _i_log_as_error "fzf is required for the SSH connection picker."
    return 1
  fi

  local connections
  connections=$(_i_ssh_load_connections)
  if [[ -z "${connections}" ]]; then
    _i_log_as_info "No SSH connections saved."
    return 0
  fi

  local selected_label
  selected_label=$(echo "${connections}" | awk -F'|' '{print $1}' | fzf --prompt="Remove > " --height=40% --reverse)
  [[ -z "${selected_label}" ]] && return 0

  read -rp "Remove connection '${selected_label}'? (y/N): " confirm
  confirm="${confirm:-n}"
  if [[ "${confirm}" == "y" ]]; then
    local file="${_NIXLPER_SSH_CONNECTIONS_FILE}"
    # Escape label for use in sed pattern
    local escaped_label
    escaped_label=$(printf '%s\n' "${selected_label}" | sed 's/[[\.*^$()+?{}|]/\\&/g')
    sed -i "/^${escaped_label}|/d" "${file}"
    _i_log_as_info "Connection '${selected_label}' removed."
  else
    _i_log_as_info "Cancelled."
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# scl: SSH Connection List — display all saved connections
#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: List all saved SSH connection profiles
# @category: SSH
# @alias: scl
function scl() {
  local connections
  connections=$(_i_ssh_load_connections)
  if [[ -z "${connections}" ]]; then
    _i_log_as_info "No SSH connections saved. Use 'sca' to add one."
    return 0
  fi

  printf '%-20s  %-15s  %-30s  %-6s  %s\n' "LABEL" "USER" "HOST" "PORT" "KEY"
  printf '%s\n' "────────────────────────────────────────────────────────────────────────────"
  while IFS= read -r line; do
    local lbl user host port key
    lbl=$(_i_ssh_parse_field "${line}" 1)
    user=$(_i_ssh_parse_field "${line}" 2)
    host=$(_i_ssh_parse_field "${line}" 3)
    port=$(_i_ssh_parse_field "${line}" 4)
    key=$(_i_ssh_parse_field "${line}" 5)
    key="${key:-(global default)}"
    printf '%-20s  %-15s  %-30s  %-6s  %s\n' "${lbl}" "${user}" "${host}" "${port}" "${key}"
  done <<< "${connections}"
}
