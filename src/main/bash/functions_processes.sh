#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: processes.sh                                                         #
#                                           DESCRIPTION: functions related to unix processes                           #
########################################################################################################################
function _interactive_kill() {
  local param_killmode=""
  local value=""
  if [[ $# -gt 0 ]]; then
    param_killmode=$1
    if [[ "${param_killmode}" == "--port" || "${param_killmode}" == "--pattern" ]]; then
      if [[ $# -gt 1 ]]; then
        value=$2
      fi
    else
      _i_log_as_error "Invalid parameter, continue with interactive call"
      param_killmode=""
    fi
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

function _i_kill_by_port() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "$0: Missing port value"
    return 1
  fi
  local -r port=$1
  local -r process_pid=$(netstat -anp | grep -i ":${port} " | awk '{print $7}' | sed 's/[^0-9]*//g' )
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
