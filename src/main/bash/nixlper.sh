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
# Initialisation
#***********************************************************************************************************************
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

function _i_init() {
  _i_create_bookmarks_file_if_not_existing
  _i_load_bookmarks
  _i_load_bindings
  _i_load_custom_libraries
}

# Custom scripts can be put in custom folder if specific things are needed
function _i_load_custom_libraries() {
  local -r custom_dir=${NIXLPER_INSTALL_DIR}/custom
  if [[ -d "${custom_dir}" ]]; then
    TODO "Source custom files"
    for i in "${custom_dir}"/* ; do
      echo "Load $i"
      # shellcheck source=/dev/null
      # shellcheck disable=SC2086
      # (putting " " does not expand correctly for my purpose)
      source $i
    done
  else
    echo "custom directory does not exist, create it. All scripts put in this folder will be sourced during next login"
    mkdir -p "${custom_dir}"
    touch "${custom_dir}/script_template.sh"
  fi
}

#***********************************************************************************************************************

#***********************************************************************************************************************
# Bookmarks
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
      while [[ -z ${answer_bookmark_name} ]]; do
          if [[ -z ${answer_bookmark_name} ]]; then
            _i_log_as_error "Bookmark cannot be empty, please enter a value"
            read -rp "Enter bookmark name: " answer_bookmark_name
          fi
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

#-----------------------------------------------------------------------------------------------------------------------
# Init bookmarks feature: create all needed items to use bookmark features
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
#-----------------------------------------------------------------------------------------------------------------------
# Bookmarks atomic actions
#-----------------------------------------------------------------------------------------------------------------------
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
#***********************************************************************************************************************

#***********************************************************************************************************************
# Files and folders
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
#***********************************************************************************************************************

#***********************************************************************************************************************
# Navigation
#***********************************************************************************************************************
# Make the navigation easier, calling this function display the following output
#
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
#
function navigate() {
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

#***********************************************************************************************************************
# Users
#***********************************************************************************************************************
function _su_to_current_directory() {
  local -r su_user=$1
  su -l -s /bin/bash -c "cd $PWD; script -q /dev/null" ${su_user}
}
#***********************************************************************************************************************

#***********************************************************************************************************************
# Help
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
# Bindings
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

#***********************************************************************************************************************
# Install/Uninstall nixlper
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
    sed 's/^/# /g' "${NIXLPER_INSTALL_DIR}"/version | grep -v PROJECT >> ~/.bashrc
    echo "################################################################################################" >> ~/.bashrc
    echo "export NIXLPER_INSTALL_DIR=$(pwd)" >> ~/.bashrc
    echo "export NIXLPER_BOOKMARKS_FILE=\${NIXLPER_INSTALL_DIR}/.nixlper_bookmarks" >> ~/.bashrc
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
########################################################################################################################

########################################################################################################################
# EXPOSED PART (exposed to end users)                                                                                  #
########################################################################################################################
#***********************************************************************************************************************
# Folders
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
# Aliases
#***********************************************************************************************************************
alias c=_mark_folder_as_current
alias cf=_mark_file_as_current
alias sucd=_su_to_current_directory
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
