#!/usr/bin/env bash
########################################################################################################################
# FILE: processes.sh
# DESCRIPTION: functions related to unix processes, killing feature is appreciable!
########################################################################################################################

# `ps` output consumed by the fuzzy picker. Kept in one place because _i_kill_candidates also
# filters this exact command line out of its own listing (see below).
_NIXLPER_KILL_PS_FORMAT="pid=,user=,args="

#-----------------------------------------------------------------------------------------------------------------------
# _i_kill_fuzzy_enabled: true when the unified fzf picker should be used instead of the
# port/pattern prompt.
#-----------------------------------------------------------------------------------------------------------------------
function _i_kill_fuzzy_enabled() {
  [[ "${NIXLPER_KILL_FUZZY:-true}" == "true" ]] && command -v fzf &>/dev/null
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_kill_parse_ss_ports: stdin = `ss -tlnp` output, stdout = "pid port" lines.
# A single socket can name several PIDs (nginx master + workers), hence the loop over every
# `pid=` occurrence rather than a single match.
#-----------------------------------------------------------------------------------------------------------------------
function _i_kill_parse_ss_ports() {
  awk '
    /pid=/ {
      split($4, addr, ":")
      port = addr[length(addr)]
      n = split($0, chunk, "pid=")
      for (i = 2; i <= n; i++) {
        split(chunk[i], p, ",")
        print p[1], port
      }
    }'
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_kill_parse_netstat_ports: stdin = `netstat -tlnp` output, stdout = "pid port" lines.
# Rows whose last field is not "PID/name" are skipped: netstat prints "-" there for sockets
# owned by another user, and a "-" would otherwise be parsed as a PID.
#-----------------------------------------------------------------------------------------------------------------------
function _i_kill_parse_netstat_ports() {
  awk '
    $NF ~ /^[0-9]+\// {
      split($4, addr, ":")
      port = addr[length(addr)]
      split($NF, p, "/")
      print p[1], port
    }'
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_kill_ports_map: "pid port" lines for every TCP listening socket, using the same ss/netstat
# preference as _i_get_pid_by_port. Emits nothing when neither tool exists — the picker then
# simply shows "-" in its ports column instead of failing.
#-----------------------------------------------------------------------------------------------------------------------
function _i_kill_ports_map() {
  if command -v ss &>/dev/null; then
    ss -tlnp 2>/dev/null | _i_kill_parse_ss_ports
  elif command -v netstat &>/dev/null; then
    netstat -tlnp 2>/dev/null | _i_kill_parse_netstat_ports
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_kill_candidates: one display line per process, "PID PORTS USER COMMAND".
# Joining the listening ports into the same line is what lets a single fzf query match either a
# command name or a port number — the whole point of the unified picker.
#
# Unlike rd/bd/lc, lines carry no leading index: here digits must mean "port or PID", so an
# index column would compete with the port for every numeric query.
#-----------------------------------------------------------------------------------------------------------------------
function _i_kill_candidates() {
  local -A ports_by_pid=()
  local pid port user args
  while read -r pid port; do
    [[ -z "${pid}" || -z "${port}" ]] && continue
    # A service bound on both 0.0.0.0:8080 and [::]:8080 must not render ":8080,:8080".
    if [[ ",${ports_by_pid[${pid}]:-}," != *",:${port},"* ]]; then
      ports_by_pid[${pid}]="${ports_by_pid[${pid}]:+${ports_by_pid[${pid}]},}:${port}"
    fi
  done < <(_i_kill_ports_map)

  while read -r pid user args; do
    [[ -z "${pid}" ]] && continue
    # Never offer the caller's own shell, nor the `ps` this function just spawned. Matched on
    # the exact command line, so a real `ps` the user does want to kill still shows up.
    [[ "${pid}" == "$$" ]] && continue
    [[ "${args}" == "ps -eo ${_NIXLPER_KILL_PS_FORMAT}" ]] && continue
    printf '%-7s %-15s %-10s %s\n' "${pid}" "${ports_by_pid[${pid}]:--}" "${user}" "${args}"
  done < <(ps -eo "${_NIXLPER_KILL_PS_FORMAT}")
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_kill_fuzzy_pick: unified picker — one prompt where a query filters on command line, PID and
# listening port at once. TAB marks several processes, ENTER validates, and nothing is killed
# before the marked list is echoed back and confirmed.
# Optional argument: initial fzf query.
#-----------------------------------------------------------------------------------------------------------------------
function _i_kill_fuzzy_pick() {
  local -r query="${1:-}"

  # Built before fzf starts, not piped into it: both sides of a pipeline run concurrently, so a
  # direct `_i_kill_candidates | fzf` would list fzf itself as a killable process.
  local candidates
  candidates=$(_i_kill_candidates)
  if [[ -z "${candidates}" ]]; then
    _i_log_as_info "No process to display."
    return 0
  fi

  local -a fzf_args=(
    --multi
    --height=60%
    --reverse
    --prompt="Kill > "
    --header="Filter by command, PID or port | TAB: mark several | ENTER: validate | ESC: cancel"
  )
  [[ -n "${query}" ]] && fzf_args+=(--query "${query}")

  local selected
  selected=$(printf '%s\n' "${candidates}" | fzf "${fzf_args[@]}")
  [[ -z "${selected}" ]] && _i_log_as_info "Action is aborted" && return 0

  local -a pids=() labels=()
  local line candidate_pid
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    # PID is the first field of the display line, so no parallel array is needed to map back.
    candidate_pid="${line%% *}"
    # A command line holding a raw newline splits into a row with no PID in front; refuse it
    # rather than handing a non-numeric argument to kill.
    if [[ ! "${candidate_pid}" =~ ^[0-9]+$ ]]; then
      _i_log_as_error "Skipping unreadable selection: ${line}"
      continue
    fi
    pids+=("${candidate_pid}")
    labels+=("${line}")
  done <<< "${selected}"

  if [[ ${#pids[@]} -eq 0 ]]; then
    _i_log_as_info "Nothing to kill, exit interactive kill"
    return 0
  fi

  echo ""
  _i_log_as_info "About to kill ${#pids[@]} process(es):"
  for line in "${labels[@]}"; do
    echo "  ${line}"
  done
  echo ""

  local answer_kill_process
  read -rp "Kill process(es) above with kill -9? (y/n, default is n)" answer_kill_process
  answer_kill_process=${answer_kill_process:-n}
  if [[ "${answer_kill_process}" != "y" ]]; then
    _i_log_as_info "Action is aborted"
    return 0
  fi

  local pid
  local failures=0
  for pid in "${pids[@]}"; do
    if kill -9 "${pid}" 2>/dev/null; then
      _i_log_as_info "Killed ${pid}"
    else
      _i_log_as_error "Could not kill ${pid} (already gone, or insufficient privileges)"
      ((failures++))
    fi
  done
  [[ ${failures} -eq 0 ]] && _i_log_as_info "-> DONE"
  return 0
}

# Opens a single fzf picker listing every process with its PID, listening ports, user and
# command line, so one query matches a name or a port without choosing a mode first. Falls back
# to the historical port/pattern prompt when fzf is missing or NIXLPER_KILL_FUZZY is false.
# @cmd-palette
# @description: Interactive kill by pattern or port (fuzzy picker via fzf)
# @category: Processes
# @alias: ik
# @interactive
function _interactive_kill() {
  local param_killmode=""
  local value=""
  local fuzzy_query=""
  if [[ $# -gt 0 ]]; then
    param_killmode=$1
    if [[ "${param_killmode}" == "--port" || "${param_killmode}" == "--pattern" ]]; then
      if [[ $# -gt 1 ]]; then
        value=$2
      fi
    else
      # Not a known flag: treat it as the initial filter for the picker rather than an error.
      fuzzy_query=$1
      param_killmode=""
    fi
  fi

  if [[ -z "${param_killmode}" ]] && _i_kill_fuzzy_enabled; then
    _i_kill_fuzzy_pick "${fuzzy_query}"
    return $?
  fi

  if [[ -n "${fuzzy_query}" ]]; then
    _i_log_as_error "Invalid parameter, continue with interactive call"
  fi

  if [[ -z "${param_killmode}" ]]; then
    local answer_killmode=""
    while [[ "${answer_killmode}" != "port" && "${answer_killmode}" != "pattern" ]]; do
      read -rp "Choose kill mode (port/pattern)" answer_killmode
      if [[  "${answer_killmode}" != "port" && "${answer_killmode}" != "pattern" ]]; then
        _i_log_as_error "Invalid kill mode!"
      fi
    done
    param_killmode="--${answer_killmode}"
  fi
  if [[ -z "${value}" ]]; then
    while [[ -z "${value}" ]]; do
      read -rp "Please enter a value: " value
      if [[ -z "${value}" ]]; then
        _i_log_as_error "Value cannot be empty!"
      fi
    done
  fi

  _i_log_as_info "Kill by ${param_killmode%--*} with value ${value}, output is:"
  case ${param_killmode} in
  --pattern)
    _i_kill_by_pattern "${value}"
    ;;
  --port)
    _i_kill_by_port "${value}"
    ;;
  *)
    _i_log_as_error "invalid kill mode"
    return 1
    ;;
  esac
}

function _i_kill_by_pattern() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "$0: Missing pattern value"
    return 1
  fi
  local kill_increment=1
  local -r pattern=$1
  while read -r i; do
    # Exit point where there is nothing to kill!
    if [[ -z "$i" ]]; then
      _i_log_as_info "Nothing to kill, exit interactive kill"
      return 0
    fi
    echo "$i (${kill_increment})"
    kill_choices[kill_increment]=$(echo "$i" | awk "{print \$2}")
    ((kill_increment++))
  done <<< "$(ps -ef | grep -i "${pattern}" | grep -v "grep")"
  ((kill_increment--))

  local kill_hint="from 1 to ${kill_increment}"
  [[ ${kill_increment} -eq 0 ]] && kill_hint="1 to kill"
  local kill_choice=""
  read -rp "Choose process to kill, enter number (${kill_hint}, if 0 or empty, action is aborted)" kill_choice
  kill_choice=${kill_choice:-0}

  if [[ ! "$kill_choice" =~ ^[0-9]+$ ]]; then
    _i_log_as_error "Not a number, action is aborted"
  elif [[ "${kill_choice}" -eq 0 ]]; then
    _i_log_as_info "Action is aborted"
  elif [[ "${kill_choice}" -gt ${kill_increment} ]]; then
    _i_log_as_error "Choice is out of range, action is aborted"
  else
    _i_log_as_info "Kill process ${kill_choices[kill_choice]}"
    kill -9 "${kill_choices[kill_choice]}"
    _i_log_as_info "-> DONE"
  fi
  _i_kill_by_pattern "${pattern}"
}

function _i_get_pid_by_port() {
  local -r port=$1
  if command -v ss &>/dev/null; then
    ss -tlnp | grep ":${port}" | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | head -1
  elif command -v netstat &>/dev/null; then
    netstat -anp 2>/dev/null | grep -i ":${port} " | awk '{print $7}' | sed 's/[^0-9]*//g' | head -1
  else
    return 1
  fi
}

# @cmd-palette
# @description: Quick-check which process is listening on a port (name + PID + suggested action)
# @category: Processes
# @alias: pc
# @args: PORT
function _port_check() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "$0: Missing port value"
    _i_log_as_error "Usage: pc PORT"
    return 1
  fi
  local -r port=$1
  if [[ ! "${port}" =~ ^[0-9]+$ ]]; then
    _i_log_as_error "Invalid port '${port}', expected a number"
    return 1
  fi

  local process_pid
  if ! process_pid=$(_i_get_pid_by_port "${port}"); then
    _i_log_as_error "No tool available to query ports. Please install ss (iproute2) or netstat (net-tools)."
    return 1
  fi

  if [[ -z "${process_pid}" ]]; then
    _i_log_as_info "No process is listening on port ${port}."
    return 0
  fi

  local process_name
  process_name=$(ps -p "${process_pid}" -o comm= 2>/dev/null)

  _i_log_as_info "Port ${port} is in use by PID ${process_pid} (${process_name:-unknown})"
  if [[ "${NIXLPER_PORT_CHECK_SHOW_CMDLINE:-true}" == "true" ]]; then
    local process_cmd
    process_cmd=$(ps -p "${process_pid}" -o args= 2>/dev/null)
    echo "Command: ${process_cmd:-n/a}"
  fi
  echo "Suggested action: run 'ik --port ${port}' to kill it interactively, or 'kill -9 ${process_pid}' directly."
}

function _i_kill_by_port() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "$0: Missing port value"
    return 1
  fi
  local -r port=$1
  local process_pid
  if ! process_pid=$(_i_get_pid_by_port "${port}"); then
    _i_log_as_error "No tool available to query ports. Please install ss (iproute2) or netstat (net-tools)."
    return 1
  fi
  if [[ -n "${process_pid}" ]]; then
    ps -p "${process_pid}" -f
    local answer_kill_process
    read -rp "Kill process above? (y/n, default is n)" answer_kill_process
    answer_kill_process=${answer_kill_process:-n}
    if [[ ${answer_kill_process} == "y" ]]; then
      kill -9 "${process_pid}"
      _i_log_as_info "-> DONE"
    else
      _i_log_as_info "Action is aborted"
    fi
  else
    _i_log_as_info "No process found by port ${port}"
  fi
}
