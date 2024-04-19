#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: nixlper.sh                                                           #
#                                           DESCRIPTION: the bash helper in an linux environment                       #
########################################################################################################################
# DEVELOPMENT NOTES
########################################################################################################################
# There is 3 types of functions:
# - <FUNCTION_NAME>: name is not starting with "_", so it can be exposed to end user
# - _<FUNCTION_NAME>: these ones can be exposed using a binding or an alias but not supposed to be called directly
# - _i_<FUNCTION_NAME>: for internal use only
########################################################################################################################
# Table of contents
########################################################################################################################
# As there is only an unique file, the table of contents is here to help to find key methods (there will not be all
# mentioned here)
# .
# ├─ DEVELOPMENT PART (not exposed to end users)
# │   ├─ CONSTANTS
# │   │   └─ Bookmarks constants
# │   ├─ DEV UTILITIES: useful for nixlper development
# │   │   ├─ "to do" function
# │   │   └─ logging functions (error, info, "action cancelled")
# │   ├─ INITIALIZATION
# │   │   ├─ _i_init: init NIXLPER
# │   │   ├─ _i_test_prerequisites: check at last if Nixlper is correctly installed
# │   │   ├─ _i_load_bindings: load existing bindings
# │   │   └─ _i_load_custom_libraries: handle custom scripts to be loaded
# │   ├─ INSTALL/UPDATE/UNINSTALL: dedicated to Nixlper install/update/uninstall
# │   ├─ BOOKMARKS
# │   │   ├─ Bookmarks mains actions: display existing bookmarks, add/remove bookmark
# │   │   │   ├─ _display_existing_bookmarks
# │   │   │   └─ _add_or_remove_bookmark
# │   │   ├─ Bookmarks initialization: create all needed items to use bookmark features
# │   │   └─ Bookmarks atomic actions: all atomic actions to handle bookmarks
# │   ├─ FILES AND FOLDERS
# │   │   ├─ _mark_folder_as_current: for immediate access to marked folder with "gc"
# │   │   ├─ _mark_file_as_current: for immediate access to marked file with "gcf"
# │   │   ├─ _snapshot_file: save file in snapshot folder
# │   │   └─ _restore_file: restore file in current folder, if called without parameter, can restore any snapshot files
# │   ├─ NAVIGATION
# │   │   ├─ navigate: a way to navigate in a more interactive way combined with dedicated bindings/aliases
# │   │   └─ _find_and_navigate: execute find command and display results in "navigate" style
# │   ├─ PROCESS
# │   │   └─ _interactive_kill: interactive kill (kill by pattern/port)
# │   ├─ USERS
# │   │   └─ _su_to_current_directory: perform a su and stay in current folder
# │   ├─ HELP: help to existing commands
# │   └─ BINDINGS: contains all binding definition !!!!
# ├─ EXPOSED PART
# │   ├─ FOLDERS
# │   │   └─ cdf: go to folder containing the filepath
# │   └─ ALIASES
# │       ├─ c: mark current folder with _mark_folder_as_current
# │       ├─ cf: mark current file with _mark_file_as_current
# │       ├─ ik: call _interactive_kill and make an interactive kill
# │       ├─ sn: snapshot a file using _snapshot_file
# │       ├─ re: restore a file using _restore_file
# │       ├─ sucd: su in current directory with _su_to_current_directory
# │       └─ fan: execute _find_and_navigate
# └─ ENTRY POINT: contains the famous main action
########################################################################################################################

########################################################################################################################
# DEVELOPMENT PART (not exposed to end users)                                                                          #
########################################################################################################################
#***********************************************************************************************************************
# CONSTANTS                                                                                                            *
#***********************************************************************************************************************
#-----------------------------------------------------------------------------------------------------------------------
# Bookmarks constants
#-----------------------------------------------------------------------------------------------------------------------
# sed pattern to display a bookmark like "/var/projects (projects_alias)" where "projects_alias" is an alias.
SED_PATTERN_EXTRACT_ALIAS="s/alias (\w+)='cd (\S+)( &&.*)/\2 (\1)/g"
#***********************************************************************************************************************

#***********************************************************************************************************************
# DEV UTILITIES: useful for nixlper development
#***********************************************************************************************************************
# Display a "to do" task with return code 1 (fail fast)
function TODO() {
  echo "TODO: $*"
  return 1
}
#-----------------------------------------------------------------------------------------------------------------------
# Logging
#-----------------------------------------------------------------------------------------------------------------------
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
  _i_log_as_info "Action is cancelled"
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# INITIALIZATION
#***********************************************************************************************************************
function _i_init() {
  _i_create_bookmarks_file_if_not_existing
  _i_create_snapshot_folder
  _i_load_bookmarks
  _i_load_bindings
  _i_load_custom_libraries
}

function _i_test_prerequisites() {
  if ! grep "export NIXLPER_INSTALL_DIR" ~/.bashrc > /dev/null 2>&1 ; then
    _i_log_as_error "NIXLPER_INSTALL_DIR is not defined, please run \"install\" command"
    return 1
  fi
  if ! grep "export NIXLPER_BOOKMARKS_FILE" ~/.bashrc > /dev/null 2>&1 ; then
    _i_log_as_error "NIXLPER_BOOKMARKS_FILE is not defined, please run \"install\" command"
    return 1
  fi
}

# Custom scripts can be put in custom folder if specific things are needed
function _i_load_custom_libraries() {
  local -r custom_dir=${NIXLPER_INSTALL_DIR}/custom
  if [[ -d "${custom_dir}" ]] ; then
    local -r nb_of_scripts=$(find "${custom_dir}" -type f | wc -l)
    if [[ ${nb_of_scripts} -gt 0 ]]; then
      echo "Custom scripts detect under ${custom_dir}:"
      for i in "${custom_dir}"/* ; do
        echo "Load $i"
        # shellcheck source=/dev/null
        # shellcheck disable=SC2086
        # (putting " " does not expand correctly for my purpose)
        source $i
    done
    fi
  else
    echo "custom directory does not exist, create it. All scripts put in this folder will be sourced during next login"
    mkdir -p "${custom_dir}"
    touch "${custom_dir}/script_template.sh"
  fi
}

function _i_create_snapshot_folder() {
  local -r snapshot_dir=${NIXLPER_INSTALL_DIR}/snapshots
  if [[ ! -d "${snapshot_dir}" ]] ; then
    echo "Snapshots directory does not exist, create it"
    mkdir -p "${snapshot_dir}"
  fi
}

#***********************************************************************************************************************

#***********************************************************************************************************************
# INSTALL/UPDATE/UNINSTALL
#***********************************************************************************************************************
function _i_install() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Install Nixlper"
  touch ~/.bashrc
  if grep "nixlper.sh" ~/.bashrc; then
    echo ".bashrc has already a reference nixlper, action is skipped"
    echo "-> SKIPPED (Install Nixlper)"
  else
    echo "Backup existing .bashrc"
    cp ~/.bashrc ~/.bashrc.ori
    _i_set_bashrc_config
    echo "Please execute one the following commands to finalize the installation:
    - source ~/.bashrc
    - logout then login again"
    echo "-> DONE (Install Nixlper)"
  fi
  echo "---------------------------------------------------------------------------------------------------------------"
}

function _i_update() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Update Nixlper configuration"
  _i_delete_bashrc_config
  _i_set_bashrc_config
  echo "-> DONE (Update Nixlper configuration)"
  echo "---------------------------------------------------------------------------------------------------------------"
}

function _i_uninstall() {
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Uninstall Nixlper"
  local -r install_dir="${NIXLPER_INSTALL_DIR}"
  echo "Delete ${NIXLPER_BOOKMARKS_FILE} file"
  rm -rf "${NIXLPER_BOOKMARKS_FILE}"
  _i_delete_bashrc_config
  echo "Delete environment variables"
  unset NIXLPER_INSTALL_DIR
  unset NIXLPER_BOOKMARKS_FILE
  echo "To permanently remove Nixlper, please remove all items from ${install_dir} with command below:
  rm -rf ${install_dir}"
  echo "-> DONE (Uninstall Nixlper)"
  echo "---------------------------------------------------------------------------------------------------------------"
}

function _i_set_bashrc_config() {
  echo "  Update .bashrc with nixlper"
  echo "" >> ~/.bashrc
  echo "################################ nixlper start #################################################" >> ~/.bashrc
  echo "# nixlper installation" >> ~/.bashrc
  # For install NIXLPER_INSTALL_DIR, is not defined
  if [[ -z "${NIXLPER_INSTALL_DIR}" ]]; then
    cd "$(dirname $0)" || return 1
    sed 's/^/# /g' "$(pwd)"/version | grep -v PROJECT >> ~/.bashrc
  else
    sed 's/^/# /g' "${NIXLPER_INSTALL_DIR}"/version | grep -v PROJECT >> ~/.bashrc
  fi
  echo "################################################################################################" >> ~/.bashrc
  echo "export NIXLPER_INSTALL_DIR=$(pwd)" >> ~/.bashrc
  echo "export NIXLPER_BOOKMARKS_FILE=\${NIXLPER_INSTALL_DIR}/.nixlper_bookmarks" >> ~/.bashrc
  echo "export NIXLPER_NAVIGATE_MODE=tree" >> ~/.bashrc
  echo "source \${NIXLPER_INSTALL_DIR}/nixlper.sh" >> ~/.bashrc
  echo "################################ nixlper stop ##################################################" >> ~/.bashrc
  source ~/.bashrc
  echo "  -> DONE (Update .bashrc with nixlper)"
}

function _i_delete_bashrc_config() {
  echo "  Remove installation from .bashrc file"
  sed -i  '/nixlper start/,/nixlper stop/d' ~/.bashrc
  echo "  -> DONE (Remove installation from .bashrc file)"
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# BOOKMARKS
#***********************************************************************************************************************
#-----------------------------------------------------------------------------------------------------------------------
# Bookmarks mains actions
#-----------------------------------------------------------------------------------------------------------------------
function _display_existing_bookmarks() {
  additional_option=""
  if [[ $# -eq 1 ]]; then
    additional_option=$1
  fi
  _i_log_as_info "Current bookmarks are: "
  sed -E "${SED_PATTERN_EXTRACT_ALIAS}" "${NIXLPER_BOOKMARKS_FILE}"
  echo ""
   # _display_existing_bookmarks is called in _add_or_remove_bookmark and we don't want to display message below
  if [[ "${additional_option}" != "HIDE" ]]; then
    local -r matching_bookmark=$(_i_get_matching_bookmark_for_current_folder)
    if [[ -z "${matching_bookmark}"  ]]; then
      echo "-> $(pwd) (not bookmarked)"
      echo "HINT: use \"CTRL + X THEN B\" to bookmark it)"
    else
      local -r current_location=$(echo "${matching_bookmark}" | sed -E "${SED_PATTERN_EXTRACT_ALIAS}")
      echo "-------------------------------------------------------------------------------------------------------------"
      echo "currently in ${current_location}"
      echo "-------------------------------------------------------------------------------------------------------------"
      echo ""
    fi
  fi
}

# Similarly to Total commander (https://www.ghisler.com/accueil.htm) this function behaves like:
# - Display existing bookmarks
# - Test if current folder is in the bookmarks
#   - if so, propose to add it to the bookmarks
#   - if no, propose to remove it from bookmarks
function _add_or_remove_bookmark() {
  _display_existing_bookmarks "HIDE"

  # test existence using path with " &&" for ending part
  local -r matching_bookmark=$(_i_get_matching_bookmark_for_current_folder)

  if [[ -z "${matching_bookmark}" ]]; then
    echo "-------------------------------------------------------------------------------------------------------------"
    echo "-> $(pwd) not bookmarked"
    echo "-------------------------------------------------------------------------------------------------------------"
    read -rp "Bookmark this folder? (y/n default y)" answer_create_bookmark
    answer_create_bookmark=${answer_create_bookmark:-y}
    if [[ ${answer_create_bookmark} == "y" ]]; then
      read -rp "Enter bookmark name: " answer_bookmark_name

      if [[ -z "${answer_bookmark_name}" ]]; then
        local -r default_value=$(basename "$(pwd)")
        read -rp "You have not enter any value, use default value \"${default_value}\" (default is y) ?" answer_use_default_value
        answer_use_default_value=${answer_use_default_value:-y}
        if [[ "${answer_use_default_value}" == "y" ]]; then
          answer_bookmark_name=${default_value}
        fi
      fi

      while ! _i_is_bookmark_name_free_and_not_empty "${answer_bookmark_name}"; do
        read -rp "Enter bookmark name: " answer_bookmark_name
      done
      _i_bookmark_directory "${answer_bookmark_name}" "$(pwd)"
      _i_log_as_info "Bookmark saved"
      _i_load_bookmarks
    else
      _i_log_as_info "Action is cancelled"
    fi
  else
    echo "-------------------------------------------------------------------------------------------------------------"
    local -r current_location=$(echo "${matching_bookmark}" | sed -E "${SED_PATTERN_EXTRACT_ALIAS}")
    echo "current bookmark -> ${current_location}"
    echo "-------------------------------------------------------------------------------------------------------------"
    read -rp "Delete bookmark? (y/n default n)" answer_delete_bookmark
    answer_delete_bookmark=${answer_delete_bookmark:-n}
    if [[ ${answer_delete_bookmark} == "y" ]]; then
      # shellcheck disable=SC2001
      local -r bookmark_name=$(echo "${current_location}" | sed  's/.*(\(.*\))/\1/g') # Alias is between "(" and ")" chars.
      _i_delete_bookmark "${bookmark_name}"
      unalias "${bookmark_name}"
      _i_log_as_info "Bookmark ${bookmark_name} is deleted"
    else
      _i_log_as_info "Action is cancelled"
    fi
  fi
}

function _i_is_bookmark_name_free_and_not_empty() {
  if [[ -z "$1" ]]; then
    _i_log_as_error "Bookmark cannot be empty, please enter a value"
    return 1
  fi

  local -r bookmark_name=$(_i_get_matching_bookmark_for_alias "$1")
  if [[ -n "${bookmark_name}" ]]; then
    _i_log_as_error "Bookmark name $1 is already used!"
    return 1
  fi
  if [[ $1 =~ ^[nv][0-9]+$ ]]; then
      _i_log_as_error "Cannot use $1 because these aliases are already used for navigate feature"
      return 1
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Bookmarks initialization
#-----------------------------------------------------------------------------------------------------------------------
function _i_create_bookmarks_file_if_not_existing() {
  if [[ ! -f $NIXLPER_BOOKMARKS_FILE ]]; then
    echo "Bookmarks file does not exist, create ${NIXLPER_BOOKMARKS_FILE}"
    touch "${NIXLPER_BOOKMARKS_FILE}"
    chmod 777 "${NIXLPER_BOOKMARKS_FILE}"
  fi
}
function _i_load_bookmarks() {
  # shellcheck disable=SC1090
  source "${NIXLPER_BOOKMARKS_FILE}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Bookmarks atomic actions
#-----------------------------------------------------------------------------------------------------------------------
function _i_bookmark_directory() {
  [[ "$1" == "--help" ]] && echo "$FUNCNAME bookmark a specific directory storing its path into a file with a specific alias.
    Thus it is possible to reach this folder using an alias.

    Usage: $0 SHORTCUT_NAME DIR_TO_BOOKMARK

    SHORTCUT_NAME: the name or the alias.
    DIR_TO_BOOKMARK: the directory to bookmark" && return 0

  local -r shortcut_name=$1
  local -r bookmarked_dir=$2

  [[ $# -ne 2 ]] && _i_log_as_error "Please specify the shortcut name and the bookmarked dir." && return 1

  # Only bookmark if not existing.
  [[ $(grep "alias ${shortcut_name}=" ${NIXLPER_BOOKMARKS_FILE}) ]] \
  || echo "alias $shortcut_name='cd $bookmarked_dir && echo \"INFO: Jump into folder $(pwd)\"'" >> "${NIXLPER_BOOKMARKS_FILE}"
}
function _i_delete_bookmark() {
  [[ "$1" == "--help" ]] && echo "$FUNCNAME delete a bookmark.

      Usage: $0 SHORTCUT_NAME

      SHORTCUT_NAME: the name or the alias." && return 0
  [[ $# -ne 1 ]] && _i_log_as_error "Please specify the bookmark to delete" && return 1
  sed -i "/alias ${1}=/d" "$NIXLPER_BOOKMARKS_FILE"
}

# Test if current folder is in your bookmarks
function _i_get_matching_bookmark_for_current_folder() {
  local -r matching_bookmark=$(grep "$(pwd) &&" "$NIXLPER_BOOKMARKS_FILE")
  echo "${matching_bookmark}"
}

# Test if an alias is already defined as a bookmark
function _i_get_matching_bookmark_for_alias() {
  local -r matching_bookmark=$(grep " $1=" "$NIXLPER_BOOKMARKS_FILE")
  echo "${matching_bookmark}"
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# FILES AND FOLDERS
#***********************************************************************************************************************
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
#***********************************************************************************************************************

#***********************************************************************************************************************
# NAVIGATION
#***********************************************************************************************************************
# Make the navigation easier, calling this navigate function display the following output depending on the display mode
#
# Tree mode
# ---------------------------------------------------------------------------------------------------------------
# ..  ↑ CTRL + X THEN U
# ├── first item (→ or ↓) SHORTCUT_COMMAND
# ├── ..
# ├── item N (→ or ↓) SHORTCUT_COMMAND
# ├── ..
# └── last item (→ or ↓) SHORTCUT_COMMAND
#
# HINT 1: use alias nNUMBER to navigate, alias vNUMBER to open a file (FILES AND FOLDERS/ALIAS MODE)
# HINT 2: use CTRL + X, NUMBER to navigate (FOLDERS ONLY/BINDING MODE)
# -> Currently in /appli/install
#---------------------------------------------------------------------------------------------------------------
#
# Flat mode
# ---------------------------------------------------------------------------------------------------------------
# Open..
# vim file1 # (v1)
# vim file2 # (v2)
# ..
# vim fileN # (vN)
# ----
# Go to subfolder
# navigate absolute_path_1 # (n1)
# navigate absolute_path_2 # (n2)
# ..
# navigate absolute_path_n # (nN)
# ----
# Go to parent folder..
# cd parent_folder # CTRL + X THEN U
# ---------------------------------------------------------------------------------------------------------------
# HINT: double click then right click for copy/paste"
# HINT: use alias nNUMBER to navigate, alias vNUMBER to open a file"
# -> Currently in current_folder"
# ---------------------------------------------------------------------------------------------------------------
function navigate() {
  if [[ "${NIXLPER_NAVIGATE_MODE}" == "tree" ]]; then
    _i_navigate_tree "$@"
  else
    _i_navigate_flat "$@"
  fi
}

function _i_navigate_tree() {
  if [[ $# -ne 0 ]]; then
    cd "$1" || return 1
  fi
  echo ""
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "..  ↑ CTRL + X THEN U"
  local -r colored_tree_output=$(tree -L 1 -C | tail -n +2 | head -n -2)
  IFS=$'\n'
  local folder_increment=1
  local file_increment=1
  local uncolored_line
  local current_item
  for i in ${colored_tree_output}; do
    uncolored_line=$(echo $i | sed 's,\x1B\[[0-9;]*[a-zA-Z],,g')
    current_item=$(echo "${uncolored_line}" | cut -d' ' -f2)
    if [[ -f "${current_item}" ]]; then
      # shellcheck disable=SC2139
      alias v${file_increment}="vim $current_item"
      echo "$i → v${file_increment}"
      ((file_increment++))
    elif [[ -d "${current_item}" ]]; then
      # shellcheck disable=SC2139
      alias n${folder_increment}="navigate $current_item"
      if [[ ${increment} -lt 10 ]]; then
        bind -x '"\C-x'${folder_increment}'": navigate '${current_item}''
        echo "$i ↓ n${folder_increment}/CTRL + X, ${folder_increment}"
      else
        echo "$i ↓ n${folder_increment}"
      fi
      ((folder_increment++))
    else
      echo "$i"
    fi
  done
  echo ""
  echo "HINT 1: use alias nNUMBER to navigate, alias vNUMBER to open a file (FILES AND FOLDERS/ALIAS MODE)"
  echo "HINT 2: use CTRL + X, NUMBER to navigate (FOLDERS ONLY/BINDING MODE)"
  echo "-> Currently in $(pwd)"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo ""
}

function _i_navigate_flat() {
  if [[ $# -ne 0 ]]; then
    cd "$1" || return 1
  fi

  local -r files_output=$(find . -mindepth 1 -maxdepth 1 -type f)
  local -r folders_output=$(find . -mindepth 1 -maxdepth 1 -type d)

  echo ""
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Open.."
  local increment=1
  for i in ${files_output}; do
    # shellcheck disable=SC2139
    alias v${increment}="vim $i"
    echo "vim ${i:2} # (v${increment})"
    ((increment++))
  done

  echo "----"
  echo "Go to subfolder.."
  increment=1
  for i in ${folders_output}; do
    # shellcheck disable=SC2139
    alias n${increment}="navigate $i"
    if [[ ${increment} -lt 10 ]]; then
      bind -x '"\C-x'${increment}'": navigate '${i}''
      echo "navigate $(pwd)/${i:2} # (n${increment} / CTRL + X, ${increment})"
    else
      echo "navigate $(pwd)/${i:2} # (n${increment})"
    fi
    ((increment++))
  done

  echo "----"
  echo "Go to parent folder.."
  # shellcheck disable=SC2046
  echo "cd $(dirname $(pwd)) # CTRL + X THEN U"

  echo "---------------------------------------------------------------------------------------------------------------"
  echo "HINT 1: double click then right click for copy/paste (FILES AND FOLDERS/MOUSE MODE)"
  echo "HINT 2: use alias nNUMBER to navigate, alias vNUMBER to open a file (FILES AND FOLDERS/ALIAS MODE)"
  echo "HINT 3: use CTRL + X, NUMBER to navigate (FOLDERS ONLY/BINDING MODE)"
  echo "-> Currently in $(pwd)"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo ""
}

# Execute "find . -iname "*PATTERN"" then display results in "navigate" style
function _find_and_navigate() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "Missing pattern for find_and_navigate"
    return 1
  elif [[ -z $1 ]]; then
    _i_log_as_error "Pattern cannot be empty for for find_and_navigate"
    return 1
  else
    local -r find_results=$(find . -iname "*$**")
    local item_increment=1
    if [[ -n ${find_results} ]]; then
      local path_depth
      local tree_chars
      echo ".."
      for i in ${find_results}; do
        tree_chars="├──"
        path_depth=$(echo "$i" | grep -o "/" | wc -l)
        for ((j=1; j <= path_depth; j++))  ; do
          tree_chars="${tree_chars}─"
        done
        if [[ -f $i ]]; then
          # shellcheck disable=SC2139
          alias v${item_increment}="vim $i"
          echo "${tree_chars} ${i:2} → v${item_increment}"
        elif [[ -d $i ]]; then
          # shellcheck disable=SC2139
          alias n${item_increment}="cd ${i} && navigate"
          echo "${tree_chars} ${i:2} ↓ n${item_increment}"
        fi
        ((item_increment++))
      done
      echo ".."
    else
      echo "No match"
    fi
  fi
}

#***********************************************************************************************************************

#***********************************************************************************************************************
# PROCESS
#***********************************************************************************************************************
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

#***********************************************************************************************************************

#***********************************************************************************************************************
# USERS
#***********************************************************************************************************************
function _su_to_current_directory() {
  local -r su_user=$1
  su -l -s /bin/bash -c "cd $PWD; script -q /dev/null" ${su_user}
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# HELP
#***********************************************************************************************************************
function _help() {
  echo "Nixlper Help: existing topics are:"
  ls "${NIXLPER_INSTALL_DIR}"/help | sed 's/help_/- /g' | sed 's/_/ /g'
  read -rp "Please enter a value (can be a pattern, for example \"bookm\": " topic_input
  topic_input=${topic_input:-""}

  if [[ -z ${topic_input} ]]; then
    for i in "${NIXLPER_INSTALL_DIR}"/help/help_* ; do
        echo "========================================================================================================="
        cat "${i}"
    done
  else
    echo "Display help for ${topic_input}"
    if ! cat "${NIXLPER_INSTALL_DIR}"/help/help_*"${topic_input}"* 2>/dev/null; then
      echo "No topic found for ${topic_input}"
    fi
  fi
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# BINDINGS
#***********************************************************************************************************************
function _i_load_bindings() {
  if [[ $- == *i* ]]; then
    # bookmarks
    bind -x '"\C-x\C-d": _display_existing_bookmarks'
    bind  '"\C-x\C-b": "_add_or_remove_bookmark\15"'
    # help
    bind '"\C-x\C-h": "_help\15"'

    # files
    bind '"\C-x\C-e":"rm -rf $(pwd)/\33\5 && cd .."' #\33\5 is ESC then CTRL+E
    bind '"\C-x\C-r":"rm -rf $(pwd)/\33\5*"' #\33\5 is ESC then CTRL+R

    # navigation
    bind '"\C-x\C-u": "cd ..\15"'
    bind -x '"\C-x\C-n": navigate'

    # instant access to this file
    bind -x '"\C-x\C-o": vim ${NIXLPER_INSTALL_DIR}/nixlper.sh'
  fi
}
#***********************************************************************************************************************

########################################################################################################################
# EXPOSED PART
########################################################################################################################
#***********************************************************************************************************************
# FOLDERS
#***********************************************************************************************************************
# Go to folder from a filepath
function cdf() {
    [[ "$1" == "--help" ]] && echo "$FUNCNAME go to the folder containing the provided path

    Usage; $0 PATH" && return 0

    [[ $# -lt 1 ]] && _i_log_as_error "Please specify a filepath." && return 1
    local -r folderpath=$(dirname "$1")
    cd "${folderpath}" || return 1
    _i_log_as_info "Now in ${folderpath}"
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# ALIASES
#***********************************************************************************************************************
alias c=_mark_folder_as_current
alias cf=_mark_file_as_current
alias ik=_interactive_kill
alias sucd=_su_to_current_directory
alias sn=_snapshot_file
alias re=_restore_file
alias fan=_find_and_navigate
#***********************************************************************************************************************
########################################################################################################################

########################################################################################################################
# ENTRY POINT                                                                                                          #
########################################################################################################################
function main() {
  if [[ $# -eq 0 ]]; then
    if _i_test_prerequisites; then
      _i_init
    fi
  else
    local -r command=$1
    case ${command} in
    install)
      _i_install
      ;;
    update)
      _i_update
      ;;
    uninstall)
      _i_uninstall
      ;;
    *)
      echo "command ${command} is unknown, use one the following ones:
            install: to install NIXLPER
            update: to update NIXLPER with higher version
            uninstall: to uninstall NIXLPER, installation will be removed"
    esac
  fi
}

main "$@"
########################################################################################################################
