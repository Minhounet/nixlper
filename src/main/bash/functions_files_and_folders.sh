#!/usr/bin/env bash
########################################################################################################################
# FILE: files_and_folders.sh
# DESCRIPTION: Operations on folders and files
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _mark_folder_as_current: similar to "c" command in vi/vim
# @cmd-palette
# @description: Mark current folder (use 'gc' to return)
# @category: Files & Folders
# @alias: c
#-----------------------------------------------------------------------------------------------------------------------
function _mark_folder_as_current() {
    local -r current_folder=$(pwd)
    _i_log_as_info "Mark ${current_folder} as current (use \"gc\")"
    # shellcheck disable=SC2139
    alias gc="cd $current_folder && echo \"Entering current folder $current_folder\""
}
#-----------------------------------------------------------------------------------------------------------------------
# _mark_file_as_current: like _mark_folder_as_current but for file, need a file as parameter
# @cmd-palette
# @description: Mark file as current (use 'gcf' to open)
# @category: Files & Folders
# @alias: cf
# @args: FILENAME
#-----------------------------------------------------------------------------------------------------------------------
function _mark_file_as_current() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: missing filename"
    return 1
  else
    local -r filepath=$1
    if [[ ${filepath} == /* ]];then
      alias gcf="$NIXLPER_EDITOR ${filepath}"
    else
      alias gcf="$NIXLPER_EDITOR $(pwd)/${filepath}"
    fi
    _i_log_as_info "Mark ${filepath} as current. Use \"gcf\" to open file"
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _snapshot_file: save a file into the snapshots area
# @cmd-palette
# @description: Snapshot file to snapshots area
# @category: Files & Folders
# @alias: sn
# @args: FILENAME
#-----------------------------------------------------------------------------------------------------------------------
function _snapshot_file() {
  if [[ $# -eq 0 ]]; then
    echo "ERROR: missing filename"
    return 1
  fi
  local absolute_filepath
  if [[ "$1" == /* ]]; then
    absolute_filepath=$1
  else
    absolute_filepath=$(pwd)/$1
  fi
  local -r snapshot_dir="${NIXLPER_SNAPSHOT_DIR:-${NIXLPER_INSTALL_DIR}/snapshots}"
  if [[ -f ${snapshot_dir}${absolute_filepath} ]]; then
    read -rp "File ${absolute_filepath} has already been saved, overwrite files? (default is y)" overwrite_file_answer
    overwrite_file_answer=${overwrite_file_answer:-y}
    if [[ ${overwrite_file_answer} == "y" ]]; then
      rm -rf "${snapshot_dir}${absolute_filepath}"
      if cp "${absolute_filepath}" "${snapshot_dir}${absolute_filepath}"; then
        _i_log_as_info "-> File ${absolute_filepath} has been saved"
      else
        _i_log_as_error "-> File ${absolute_filepath} could not be saved"
        return 1
      fi
    else
      _i_log_as_info "-> Action is aborted"
    fi
  else
    mkdir -p "$(dirname "${snapshot_dir}${absolute_filepath}")"
    if cp "${absolute_filepath}" "${snapshot_dir}${absolute_filepath}"; then
      _i_log_as_info "-> File ${absolute_filepath} has been saved"
    else
      _i_log_as_error "-> File ${absolute_filepath} could not be saved"
      return 1
    fi
  fi
}
#-----------------------------------------------------------------------------------------------------------------------
# _restore_file: restore a file which has been saved before. Can be used in interactive mode if no argument is provided
# @cmd-palette
# @description: Restore file from snapshots
# @category: Files & Folders
# @alias: re
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function _restore_file() {
  if [[ $# -eq 0 ]]; then
      _i_restore_file_interactive
  else
    local -r absolute_filepath=$(pwd)/$1
    local -r snapshot_dir="${NIXLPER_SNAPSHOT_DIR:-${NIXLPER_INSTALL_DIR}/snapshots}"
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

#-----------------------------------------------------------------------------------------------------------------------
# _i_restore_file_interactive: restore file in interactive mode
#-----------------------------------------------------------------------------------------------------------------------
function _i_restore_file_interactive() {
  local -r snapshot_dir="${NIXLPER_SNAPSHOT_DIR:-${NIXLPER_INSTALL_DIR}/snapshots}"
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

#-----------------------------------------------------------------------------------------------------------------------
# _change_directory_from_filepath: go to folder from filepath.
# _change_directory_from_filepath /tmp/test.sh will bring you to /tmp. Very useful when combined with locate command
# before
# @cmd-palette
# @description: Change to the folder containing a file
# @category: Files & Folders
# @alias: cdf
# @args: FILEPATH
#-----------------------------------------------------------------------------------------------------------------------
function _change_directory_from_filepath() {
    [[ "$1" == "--help" ]] && echo "$FUNCNAME go to the folder containing the provided path

    Usage; $0 PATH" && return 0

    [[ $# -lt 1 ]] && _i_log_as_error "Please specify a filepath." && return 1
    local -r folderpath=$(dirname "$1")
    cd "${folderpath}" || return 1
    _i_log_as_info "Now in ${folderpath}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _open_latest_file: Opens the most recently modified file in the current repository.
# @cmd-palette
# @description: Open the most recently modified file in the current repository
# @category: Files & Folders
# @alias: olf
#-----------------------------------------------------------------------------------------------------------------------
function _open_latest_file() {
    local latest_file
    local editor="${NIXLPER_EDITOR:-vim}" # Use NIXLPER_EDITOR if set, otherwise default to vim

    # Find the latest modified file, excluding common build/version control directories
    latest_file=$(find . -type f \
        -not -path "./.git/*" \
        -not -path "./build/*" \
        -not -path "./.gemini/*" \
        -print0 | xargs -0 stat -c '%Y %n' 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2-)

    if [[ -n "${latest_file}" ]]; then
        _i_log_as_info "Opening latest modified file: ${latest_file} with ${editor}"
        "${editor}" "${latest_file}"
    else
        _i_log_as_error "No files found or could not determine the latest file."
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _rename_file_pattern: rename a file by removing or replacing a pattern
# @cmd-palette
# @description: Rename file by removing or replacing a pattern
# @category: Files & Folders
# @alias: rn
# @args: FILENAME PATTERN [REPLACEMENT]
#-----------------------------------------------------------------------------------------------------------------------
function _rename_file_pattern() {
    [[ "$1" == "--help" ]] && echo "$FUNCNAME: Rename file by removing or replacing a pattern

Usage: $0 FILENAME PATTERN [REPLACEMENT]

  FILENAME    - File to rename
  PATTERN     - Pattern to remove or replace
  REPLACEMENT - (Optional) Replacement text. If not provided, pattern is removed

Examples:
  $0 file_peppa.txt _peppa              # Results in: file.txt
  $0 test-old.txt -old -new             # Results in: test-new.txt
  $0 document_draft.pdf _draft          # Results in: document.pdf
" && return 0

    # Validate arguments
    if [[ $# -lt 2 ]]; then
        _i_log_as_error "Missing required arguments. Usage: rn FILENAME PATTERN [REPLACEMENT]"
        return 1
    fi

    local -r original_file="$1"
    local -r pattern="$2"
    local -r replacement="${3:-}" # Default to empty string if not provided

    # Check if file exists
    if [[ ! -e "${original_file}" ]]; then
        _i_log_as_error "File not found: ${original_file}"
        return 1
    fi

    # Get directory and filename
    local dir_path
    local filename
    if [[ "${original_file}" == */* ]]; then
        dir_path=$(dirname "${original_file}")
        filename=$(basename "${original_file}")
    else
        dir_path="."
        filename="${original_file}"
    fi

    # Replace pattern in filename
    local new_filename="${filename//$pattern/$replacement}"

    # Check if anything changed
    if [[ "${filename}" == "${new_filename}" ]]; then
        _i_log_as_error "Pattern '${pattern}' not found in filename '${filename}'"
        return 1
    fi

    # Build full paths
    local new_file
    if [[ "${dir_path}" == "." ]]; then
        new_file="${new_filename}"
    else
        new_file="${dir_path}/${new_filename}"
    fi

    # Check if target file already exists
    if [[ -e "${new_file}" ]] && [[ "${new_file}" != "${original_file}" ]]; then
        read -rp "File ${new_file} already exists. Overwrite? (y/n, default is n): " overwrite_answer
        overwrite_answer=${overwrite_answer:-n}
        if [[ "${overwrite_answer}" != "y" ]]; then
            _i_log_as_info "-> Rename cancelled"
            return 1
        fi
        rm -f "${new_file}"
    fi

    # Perform the rename
    mv "${original_file}" "${new_file}"

    if [[ $? -eq 0 ]]; then
        _i_log_as_info "-> Renamed: ${original_file} → ${new_file}"
        _i_log_ok
    else
        _i_log_as_error "Failed to rename file"
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_replace_pick_delimiter: echo the first :s delimiter found in neither $1 (search) nor $2 (replacement).
# Picking it automatically means the user never has to escape "/" in paths. Returns 1 if none is free.
#-----------------------------------------------------------------------------------------------------------------------
function _i_replace_pick_delimiter() {
  local d
  for d in '/' '#' '@' '!' '%' '~' ',' ';' ':' '+' '='; do
    if [[ "$1" != *"${d}"* && "$2" != *"${d}"* ]]; then
      printf '%s' "${d}"
      return 0
    fi
  done
  return 1
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_replace_has_bare_pipe: succeed if $1 contains a "|" not escaped by a backslash. ex treats a bare "|" as a command
# separator, so letting one through would execute whatever follows as an ex command.
#-----------------------------------------------------------------------------------------------------------------------
function _i_replace_has_bare_pipe() {
  local -r stripped="${1//\\\\/}" # drop escaped backslashes so "\\|" is seen as a bare pipe
  [[ "${stripped}" =~ (^|[^\\])\| ]]
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_replace_ex_run: apply an ex command to a file, silently and with the user's vimrc ignored (deterministic result).
# nofixeol keeps a missing final newline missing.
#-----------------------------------------------------------------------------------------------------------------------
function _i_replace_ex_run() {
  local -r ex_cmd="$1" target="$2"
  ex -N -u NONE -i NONE -s -c 'set nofixeol' -c "${ex_cmd}" -c 'wq' -- "${target}" < /dev/null > /dev/null 2>&1
}

#-----------------------------------------------------------------------------------------------------------------------
# _replace_in_file: interactive search & replace in a file, using vi's :s syntax.
# Builds ":RANGE s/SEARCH/REPLACE/FLAGS", previews the changed lines, then applies it after confirmation.
# @cmd-palette
# @description: Interactive search and replace in a file (vi :s syntax)
# @category: Files & Folders
# @alias: rp
# @args: FILENAME
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function _replace_in_file() {
  if [[ $# -ne 1 ]]; then
    _i_log_as_error "Usage: rp FILENAME"
    return 1
  fi
  local -r file="$1"
  if [[ ! -f "${file}" ]]; then
    _i_log_as_error "File not found: ${file}"
    return 1
  fi
  if [[ ! -w "${file}" ]]; then
    _i_log_as_error "File is not writable: ${file}"
    return 1
  fi
  if [[ -s "${file}" ]] && ! grep -Iq '' "${file}"; then
    _i_log_as_error "Binary file, refusing to edit: ${file}"
    return 1
  fi
  if ! command -v ex > /dev/null 2>&1; then
    _i_log_as_error "'ex' not found: install vim to use rp"
    return 1
  fi

  local search replace range flags
  read -erp "Search  (vi regex, e.g. foo\(.*\)): " search
  if [[ -z "${search}" ]]; then
    _i_log_action_cancelled
    return 1
  fi
  read -erp "Replace (\1 and & work as in vi): " replace
  read -erp "Lines   (Enter = all, or 10,20 or /start/,/end/): " range
  read -erp "Flags   (g = every match per line, i = ignore case, c = confirm each; default g): " flags
  range="${range:-%}"
  flags="${flags:-g}"

  if [[ ! "${flags}" =~ ^[giIc]*$ ]]; then
    _i_log_as_error "Invalid flags '${flags}' (allowed: g i I c)"
    return 1
  fi
  if _i_replace_has_bare_pipe "${search}"; then
    _i_log_as_error "Bare '|' in search is not supported: use [|] for a literal pipe or \\| for alternation"
    return 1
  fi
  if _i_replace_has_bare_pipe "${replace}"; then
    _i_log_as_error "Bare '|' in replacement is not supported: use \\| for a literal pipe"
    return 1
  fi
  if [[ "${range}" == *$'\n'* ]] || { [[ "${range}" == *'|'* ]]; }; then
    _i_log_as_error "Invalid line range '${range}'"
    return 1
  fi

  local delim
  if ! delim="$(_i_replace_pick_delimiter "${search}" "${replace}")"; then
    _i_log_as_error "Could not find a free delimiter: simplify the search or replacement"
    return 1
  fi
  local -r ex_cmd="${range}s${delim}${search}${delim}${replace}${delim}${flags}"
  _i_log_as_info "Command: :${ex_cmd}"

  local confirm_each="false"
  [[ "${flags}" == *c* ]] && confirm_each="true"

  if [[ "${confirm_each}" == "false" ]]; then
    # Dry run on a temporary copy, then show only what changes
    local tmp
    tmp="$(mktemp)" || return 1
    cp -- "${file}" "${tmp}"
    _i_replace_ex_run "${ex_cmd}" "${tmp}"
    local -r nb_changed="$(diff --unchanged-line-format= --old-line-format='x
' --new-line-format= "${file}" "${tmp}" | wc -l)"
    if [[ "${nb_changed}" -eq 0 ]]; then
      _i_log_as_info "No change: pattern not found (or replacement identical)"
      rm -f -- "${tmp}"
      return 0
    fi
    diff --unchanged-line-format= --old-line-format='%4dn - %L' --new-line-format='%4dn + %L' "${file}" "${tmp}"
    _i_log_as_info "${nb_changed} line(s) would change in ${file}"
    local apply
    read -rp "Apply? (y/n, default is n): " apply
    if [[ "${apply:-n}" != "y" ]]; then
      rm -f -- "${tmp}"
      _i_log_action_cancelled
      return 0
    fi
    _i_replace_snapshot "${file}"
    cat -- "${tmp}" > "${file}" # cat > keeps the original inode, permissions and ownership
    rm -f -- "${tmp}"
    _i_log_as_info "-> ${nb_changed} line(s) replaced in ${file}"
    _i_log_ok
  else
    if ! command -v vim > /dev/null 2>&1; then
      _i_log_as_error "Confirm mode (flag c) needs vim"
      return 1
    fi
    _i_replace_snapshot "${file}"
    vim -N -u NONE -i NONE -c 'set nofixeol' -c "${ex_cmd}" -c 'wq' -- "${file}"
    _i_log_as_info "-> Done"
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _i_replace_snapshot: save a restore point (for "re") before rp edits a file, if NIXLPER_REPLACE_SNAPSHOT is true.
# An existing snapshot is only overwritten with the user's consent, so a deliberate "sn" is never lost silently.
#-----------------------------------------------------------------------------------------------------------------------
function _i_replace_snapshot() {
  [[ "${NIXLPER_REPLACE_SNAPSHOT:-true}" == "true" ]] || return 0
  local -r absolute_filepath="$(realpath -- "$1")"
  local -r snapshot_dir="${NIXLPER_SNAPSHOT_DIR:-${NIXLPER_INSTALL_DIR}/snapshots}"
  local -r snapshot_file="${snapshot_dir}${absolute_filepath}"
  if [[ -f "${snapshot_file}" ]]; then
    local overwrite
    read -rp "A snapshot of this file already exists, overwrite it with the current version? (y/n, default is n): " overwrite
    if [[ "${overwrite:-n}" != "y" ]]; then
      _i_log_as_info "-> Existing snapshot kept (re will restore that older version)"
      return 0
    fi
  fi
  mkdir -p "$(dirname "${snapshot_file}")" && cp -- "${absolute_filepath}" "${snapshot_file}" &&
    _i_log_as_info "-> Snapshot saved, use \"re\" to undo"
}
