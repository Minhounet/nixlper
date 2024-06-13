#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: files_and_folders.sh                                                 #
#                                           DESCRIPTION: functions related to files and folders                        #
########################################################################################################################
function _mark_folder_as_current() {
    local -r current_folder=$(pwd)
    _i_log_as_info "Mark ${current_folder} as current (use \"gc\")"
    # shellcheck disable=SC2139
    alias gc="cd $current_folder && echo \"Entering current folder $current_folder\""
}

function _mark_file_as_current() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: missing filename"
    return 1
  else
    local -r filepath=$1
    if [[ ${filepath} == /* ]];then
      alias gcf="vim ${filepath}"
    else
      alias gcf="vim $(pwd)/${filepath}"
    fi
    _i_log_as_info "Mark ${filepath} as current. Use \"gcf\" to open file"
  fi
}

function _snapshot_file() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: missing filename"
    return 1
  fi
  local -r absolute_filepath=$(pwd)/$1
  local -r snapshot_dir=${NIXLPER_INSTALL_DIR}/snapshots
  if [[ -f ${snapshot_dir}${absolute_filepath} ]]; then
    read -rp "File ${absolute_filepath} has already been saved, overwrite files? (default is y)" overwrite_file_answer
    overwrite_file_answer=${overwrite_file_answer:-y}
    if [[ ${overwrite_file_answer} == "y" ]]; then
      rm -rf "${snapshot_dir}${absolute_filepath}"
      cp "${absolute_filepath}" "${snapshot_dir}${absolute_filepath}"
      _i_log_as_info "-> File ${absolute_filepath} has been saved"
    else
      _i_log_as_info "-> Action is aborted"
    fi
  else
    mkdir -p "$(dirname "${snapshot_dir}${absolute_filepath}")"
    cp "${absolute_filepath}" "${snapshot_dir}${absolute_filepath}"
    _i_log_as_info "-> File ${absolute_filepath} has been saved"
  fi
}

function _restore_file() {
  if [[ $# -eq 0 ]]; then
      _i_restore_file_interactive
  else
    local -r absolute_filepath=$(pwd)/$1
    local -r snapshot_dir=${NIXLPER_INSTALL_DIR}/snapshots
    if [[ -f ${snapshot_dir}${absolute_filepath} ]]; then
      read -rp "Restore ${absolute_filepath} ? (default is y)" restore_file_answer
      restore_file_answer=${restore_file_answer:-y}
      if [[ ${restore_file_answer} == "y" ]]; then
        rm -rf "${absolute_filepath}"
        cp "${snapshot_dir}${absolute_filepath}" "${absolute_filepath}"
        rm -rf "${snapshot_dir}${absolute_filepath}"
        _i_log_as_info "-> File ${absolute_filepath} has been restored"
      else
        _i_log_as_info "-> Action is aborted"
      fi
    else
     _i_log_as_error "There is nothing to restore, no snapshot has been done for ${absolute_filepath}"
    fi
  fi
}

function _i_restore_file_interactive() {
  local -r snapshot_dir=${NIXLPER_INSTALL_DIR}/snapshots
  cd "${snapshot_dir}" || (_i_log_as_error "snapshots dir does not exist" && return 1)
  if [[ $(find . -type f | wc -l) -gt 0 ]]; then

    local file_increment=1
    local -a restorable_files
    _i_log_as_info "List of snapshot files:"
    for i in $(find . -type f | sed 's/^.//g' ); do
      echo "$i (${file_increment})"
      restorable_files[${file_increment}]=$i
      ((file_increment++))
    done
    ((file_increment--)) # just to use last increment
    local choice_restore=""
    while [[ -z ${choice_restore} ]]; do
      if [[ ${file_increment} -gt 1 ]]; then
        read -rp "Choose a number (from 1 to ${file_increment}): " choice_restore
      else
        read -rp "Enter 1 to restore file: " choice_restore
      fi
      if [[ -z ${choice_restore} ]]; then
        _i_log_as_error "empty answer! Please choose a number between 1 and $((file_increment))"
      else
        mv "${snapshot_dir}${restorable_files[choice_restore]}" "${restorable_files[choice_restore]}"
        _i_log_as_info "File ${restorable_files[choice_restore]} has been restored"
      fi
    done
  else
    _i_log_as_info "There is nothing to restore"
  fi
  cd - || (_i_log_as_error "error when going back to original folder after restore action" && return 1)
}

# Go to folder from a filepath
function cdf() {
    [[ "$1" == "--help" ]] && echo "$FUNCNAME go to the folder containing the provided path

    Usage; $0 PATH" && return 0

    [[ $# -lt 1 ]] && _i_log_as_error "Please specify a filepath." && return 1
    local -r folderpath=$(dirname "$1")
    cd "${folderpath}" || return 1
    _i_log_as_info "Now in ${folderpath}"
}
