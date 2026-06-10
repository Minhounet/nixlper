#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_target.sh
# DESCRIPTION: Target folder staging — copy/mark files to a shared staging area under /tmp
########################################################################################################################

export NIXLPER_TARGET_DIR="${NIXLPER_TARGET_DIR:-/tmp/nixlper_target}"
export NIXLPER_MARKS_FILE="${NIXLPER_MARKS_FILE:-/tmp/.nixlper_marks_${USER}}"

#-----------------------------------------------------------------------------------------------------------------------
# _i_target_ensure_dir: create target dir if missing, with world-readable permissions
#-----------------------------------------------------------------------------------------------------------------------
function _i_target_ensure_dir() {
  if [[ ! -d "${NIXLPER_TARGET_DIR}" ]]; then
    mkdir -p "${NIXLPER_TARGET_DIR}" && chmod 755 "${NIXLPER_TARGET_DIR}"
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# target_copy: copy a file to NIXLPER_TARGET_DIR and make it world-readable
# @cmd-palette
# @description: Copy a file to the target staging folder
# @category: Target
# @alias: tc
# @args: FILEPATH
#-----------------------------------------------------------------------------------------------------------------------
function target_copy() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "Usage: tc FILEPATH"
    return 1
  fi
  local -r src="$1"
  if [[ ! -f "${src}" ]]; then
    _i_log_as_error "File not found: ${src}"
    return 1
  fi
  _i_target_ensure_dir
  cp "${src}" "${NIXLPER_TARGET_DIR}/" && chmod 644 "${NIXLPER_TARGET_DIR}/$(basename "${src}")"
  echo "Copied $(basename "${src}") → ${NIXLPER_TARGET_DIR}/"
}
alias tc='target_copy'

#-----------------------------------------------------------------------------------------------------------------------
# target_set: change the target folder for this session
# @cmd-palette
# @description: Set the target staging folder
# @category: Target
# @alias: tsd
# @args: DIRPATH
#-----------------------------------------------------------------------------------------------------------------------
function target_set() {
  if [[ $# -eq 0 ]]; then
    echo "Current target folder: ${NIXLPER_TARGET_DIR}"
    return 0
  fi
  export NIXLPER_TARGET_DIR="$1"
  echo "Target folder set to: ${NIXLPER_TARGET_DIR}"
}
alias tsd='target_set'

#-----------------------------------------------------------------------------------------------------------------------
# target_mark: add a file to the mark list (no-op if already marked)
# @cmd-palette
# @description: Mark a file for batch pack to target folder
# @category: Target
# @alias: tm
# @args: FILEPATH
#-----------------------------------------------------------------------------------------------------------------------
function target_mark() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "Usage: tm FILEPATH"
    return 1
  fi
  local -r src="$(realpath "$1" 2>/dev/null || echo "$1")"
  if [[ ! -f "${src}" ]]; then
    _i_log_as_error "File not found: ${src}"
    return 1
  fi
  if grep -qxF "${src}" "${NIXLPER_MARKS_FILE}" 2>/dev/null; then
    echo "Already marked: ${src}"
    return 0
  fi
  echo "${src}" >> "${NIXLPER_MARKS_FILE}"
  echo "Marked: ${src}"
}
alias tm='target_mark'

#-----------------------------------------------------------------------------------------------------------------------
# target_list_marks: display currently marked files
# @cmd-palette
# @description: List all files currently marked for target pack
# @category: Target
# @alias: tml
#-----------------------------------------------------------------------------------------------------------------------
function target_list_marks() {
  if [[ ! -f "${NIXLPER_MARKS_FILE}" ]] || [[ ! -s "${NIXLPER_MARKS_FILE}" ]]; then
    echo "No marked files."
    return 0
  fi
  echo "Marked files (→ ${NIXLPER_TARGET_DIR}):"
  local i=1
  while IFS= read -r line; do
    echo "  ${i}) ${line}"
    ((i++))
  done < "${NIXLPER_MARKS_FILE}"
}
alias tml='target_list_marks'

#-----------------------------------------------------------------------------------------------------------------------
# target_unmark: interactively remove a file from the mark list by number
# @cmd-palette
# @description: Remove a file from the mark list (numbered menu)
# @category: Target
# @alias: tum
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function target_unmark() {
  if [[ ! -f "${NIXLPER_MARKS_FILE}" ]] || [[ ! -s "${NIXLPER_MARKS_FILE}" ]]; then
    echo "No marked files."
    return 0
  fi
  echo "Marked files:"
  local i=1
  while IFS= read -r line; do
    echo "  ${i}) ${line}"
    ((i++))
  done < "${NIXLPER_MARKS_FILE}"
  echo -n "Remove # (or 'q' to cancel): "
  read -r choice
  [[ "${choice}" == "q" ]] && return 0
  if [[ "${choice}" =~ ^[0-9]+$ ]]; then
    local total
    total=$(wc -l < "${NIXLPER_MARKS_FILE}")
    if [[ "${choice}" -ge 1 && "${choice}" -le "${total}" ]]; then
      local removed
      removed=$(sed -n "${choice}p" "${NIXLPER_MARKS_FILE}")
      sed -i "${choice}d" "${NIXLPER_MARKS_FILE}"
      echo "Removed: ${removed}"
    else
      echo "Invalid number."
    fi
  else
    echo "Invalid input."
  fi
}
alias tum='target_unmark'

#-----------------------------------------------------------------------------------------------------------------------
# target_clear_marks: clear all marks without packing
# @cmd-palette
# @description: Clear all marks without copying anything
# @category: Target
# @alias: tcm
#-----------------------------------------------------------------------------------------------------------------------
function target_clear_marks() {
  if [[ -f "${NIXLPER_MARKS_FILE}" ]]; then
    rm -f "${NIXLPER_MARKS_FILE}"
    echo "All marks cleared."
  else
    echo "No marks to clear."
  fi
}
alias tcm='target_clear_marks'

#-----------------------------------------------------------------------------------------------------------------------
# target_pack: pack all marked files into a timestamped .tgz in NIXLPER_TARGET_DIR, world-readable, then clear marks
# @cmd-palette
# @description: Pack all marked files into a .tgz in the target folder
# @category: Target
# @alias: tp
#-----------------------------------------------------------------------------------------------------------------------
function target_pack() {
  if [[ ! -f "${NIXLPER_MARKS_FILE}" ]] || [[ ! -s "${NIXLPER_MARKS_FILE}" ]]; then
    echo "No marked files to pack."
    return 0
  fi
  _i_target_ensure_dir
  local -r archive_name="nixlper_pack_$(date +%Y%m%d_%H%M%S).tgz"
  local -r archive_path="${NIXLPER_TARGET_DIR}/${archive_name}"
  echo "Packing marked files into ${archive_path} ..."
  if tar -czf "${archive_path}" -T "${NIXLPER_MARKS_FILE}" 2>/dev/null; then
    chmod 644 "${archive_path}"
    echo "Created: ${archive_path}"
    target_clear_marks
  else
    _i_log_as_error "tar failed — check that all marked files still exist (run tml to review)."
    return 1
  fi
}
alias tp='target_pack'

#-----------------------------------------------------------------------------------------------------------------------
# target_clean: delete all files inside NIXLPER_TARGET_DIR (with confirmation)
# @cmd-palette
# @description: Delete all files in the target staging folder
# @category: Target
# @alias: tclean
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function target_clean() {
  if [[ ! -d "${NIXLPER_TARGET_DIR}" ]]; then
    echo "Target folder does not exist: ${NIXLPER_TARGET_DIR}"
    return 0
  fi
  local count
  count=$(find "${NIXLPER_TARGET_DIR}" -maxdepth 1 -mindepth 1 | wc -l)
  if [[ "${count}" -eq 0 ]]; then
    echo "Target folder is already empty: ${NIXLPER_TARGET_DIR}"
    return 0
  fi
  echo "This will delete ${count} item(s) from ${NIXLPER_TARGET_DIR}:"
  find "${NIXLPER_TARGET_DIR}" -maxdepth 1 -mindepth 1 -printf "  %f\n"
  echo -n "Confirm? [y/N]: "
  read -r confirm
  if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
    rm -rf "${NIXLPER_TARGET_DIR:?}"/*
    echo "Target folder cleaned."
  else
    echo "Cancelled."
  fi
}
alias tclean='target_clean'
