#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: functions_tips.sh                                                    #
#                                           DESCRIPTION: tip of the session                                            #
########################################################################################################################

_NIXLPER_TIPS_FILE="${NIXLPER_INSTALL_DIR}/help/tips"
_NIXLPER_TIPS_INDEX_FILE="${HOME}/.local/share/nixlper/last_tip_index"

function _i_load_tips() {
  if [[ "${NIXLPER_DISABLE_TIPS:-false}" == "true" ]]; then
    return
  fi
  _i_show_tip_sequential
}

# @cmd-palette
# @description: Show a random Nixlper tip
# @category: Help
# @keybind: CTRL+X+T
# @alias: tip
function show_random_tip() {
  local tips_file="${NIXLPER_INSTALL_DIR}/help/tips"
  if [[ ! -f "${tips_file}" ]]; then
    return
  fi
  local count
  count=$(_i_count_tips "${tips_file}")
  if [[ ${count} -eq 0 ]]; then
    return
  fi
  local index=$(( RANDOM % count ))
  _i_print_tip "${tips_file}" "${index}"
}

function _i_show_tip_sequential() {
  local tips_file="${NIXLPER_INSTALL_DIR}/help/tips"
  if [[ ! -f "${tips_file}" ]]; then
    return
  fi
  local count
  count=$(_i_count_tips "${tips_file}")
  if [[ ${count} -eq 0 ]]; then
    return
  fi

  local index=0
  if [[ -f "${_NIXLPER_TIPS_INDEX_FILE}" ]]; then
    index=$(cat "${_NIXLPER_TIPS_INDEX_FILE}" 2>/dev/null || echo 0)
    index=$(( (index + 1) % count ))
  fi
  mkdir -p "$(dirname "${_NIXLPER_TIPS_INDEX_FILE}")"
  echo "${index}" > "${_NIXLPER_TIPS_INDEX_FILE}"

  _i_print_tip "${tips_file}" "${index}"
}

function _i_count_tips() {
  local tips_file="$1"
  grep -c "^HOOK:" "${tips_file}" 2>/dev/null || echo 0
}

function _i_print_tip() {
  local tips_file="$1"
  local target_index="$2"

  local hook="" how="" current_index=-1
  while IFS= read -r line; do
    if [[ "${line}" =~ ^HOOK:\ (.*) ]]; then
      (( current_index++ ))
      hook="${BASH_REMATCH[1]}"
      how=""
    elif [[ "${line}" =~ ^HOW:\ (.*) ]]; then
      how="${BASH_REMATCH[1]}"
      if [[ ${current_index} -eq ${target_index} ]]; then
        break
      fi
    fi
  done < "${tips_file}"

  if [[ -z "${hook}" ]]; then
    return
  fi

  local width=50
  local border
  border=$(printf '─%.0s' $(seq 1 ${width}))
  echo "╭─ 💡 Nixlper tip ${border}╮"
  printf "│  %-${width}s  │\n" "${hook}"
  printf "│  %-${width}s  │\n" "→ ${how}"
  echo "╰──────────────────${border}╯"
}
