#!/usr/bin/env bash
# **********************************************************************************************************************
# DEVELOPMENT PART (not supposed to be exposed)
# **********************************************************************************************************************
# ----------------------------------------------------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------------------------------------------------
# Bookmark constants
# sed pattern to display a bookmark like "/var/projects (projects_alias)" where "projects_alias" is an alias.
SED_PATTERN_EXTRACT_ALIAS="s/alias (\w+)='cd (\S+)( &&.*)/\2 (\1)/g"
# ----------------------------------------------------------------------------------------------------------------------
# DEV utilities
# ----------------------------------------------------------------------------------------------------------------------
# >Debugging
function _debug_display_variables() {
    echo "Install dir NIXLPER_INSTALL_DIR is ${NIXLPER_INSTALL_DIR}"
}
# >Useful to test new feature before implementing it
function _debug_open_executable() {
  vim "${NIXLPER_INSTALL_DIR}"/nixlper.sh
}
function TODO() {
  echo "TODO: $*"
}
# >Logging
function _log() {
  local -r category=$1
  local message=${@:2}
  local -r date=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${date} ${category} ${message}"
}
function _log_as_error() {
  _log "ERROR" $@
}
function _log_as_info() {
  _log "INFO" $@
}
function _log_action_cancelled() {
  _log_as_info "Action is cancelled"
}
# ----------------------------------------------------------------------------------------------------------------------
# Bookmarks
# ----------------------------------------------------------------------------------------------------------------------
# >Initializing bookmarks
function _create_bookmarks_file_if_not_existing() {
  if [[ ! -f $NIXLPER_BOOKMARKS_FILE ]]; then
    echo "Bookmarks file does not exist, create ${NIXLPER_BOOKMARKS_FILE}"
    touch "${NIXLPER_BOOKMARKS_FILE}"
    chmod 777 "${NIXLPER_BOOKMARKS_FILE}"
  fi
}
function _load_bookmarks() {
  source "${NIXLPER_BOOKMARKS_FILE}"
}

# >Bookmark atomic actions
function _bookmark_directory() {
  [[ "$1" == "--help" ]] && echo "$FUNCNAME bookmark a specific directory storing its path into a file with a specific alias.
    Thus it is possible to reach this folder using an alias.

    Usage: $0 SHORTCUT_NAME DIR_TO_BOOKMARK

    SHORTCUT_NAME: the name or the alias.
    DIR_TO_BOOKMARK: the directory to bookmark" && return 0

  local -r shortcut_name=$1
  local -r bookmarked_dir=$2

  [[ $# -ne 2 ]] && _log_as_error "Please specify the shortcut name and the bookmarked dir." && return 1

  # Only bookmark if not existing.
  [[ $(grep "alias ${shortcut_name}=" ${NIXLPER_BOOKMARKS_FILE}) ]] || echo "alias $shortcut_name='cd $bookmarked_dir && echo \"INFO: Jump into folder $(pwd)\"'" >> "${NIXLPER_BOOKMARKS_FILE}"
}

function _delete_bookmark() {
  [[ "$1" == "--help" ]] && echo "$FUNCNAME delete a bookmark.

      Usage: $0 SHORTCUT_NAME

      SHORTCUT_NAME: the name or the alias." && return 0
  [[ $# -ne 1 ]] && _log_as_error "Please specify the bookmark to delete" && return 1
  sed -i "/alias ${1}=/d" "$NIXLPER_BOOKMARKS_FILE"
}

# >Key bookmarks action
function _display_existing_bookmarks() {
  _log_as_info "Current bookmarks are: "
  sed -E "${SED_PATTERN_EXTRACT_ALIAS}" "${NIXLPER_BOOKMARKS_FILE}"
}

# Similarly to Total commander, is the main function to bookmark current folder if not done, or to remove current folder from bookmarks
function _add_or_remove_bookmark() {
  _display_existing_bookmarks

  # test existence using path with " &&" for ending part
  local -r matching_bookmark=$(grep "$(pwd) &&" "$NIXLPER_BOOKMARKS_FILE")

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
            _log_as_error "Bookmark cannot be empty, please enter a value"
            read -rp "Enter bookmark name: " answer_bookmark_name
          fi
      done
      _bookmark_directory "${answer_bookmark_name}" "$(pwd)"
      _log_as_info "Bookmark saved"
      _load_bookmarks
    else
      _log_as_info "Action is cancelled"
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
      _delete_bookmark "${bookmark_name}"
      unalias "${bookmark_name}"
      _log_as_info "Bookmark ${bookmark_name} is deleted"
    else
      _log_as_info "Action is cancelled"
    fi
  fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Folders
# ----------------------------------------------------------------------------------------------------------------------
function _mark_folder_as_current() {
    local -r current_folder=$(pwd)
    _log_as_info "Mark ${current_folder} as current (use \"gc\")"
    # shellcheck disable=SC2139
    alias gc="cd $current_folder && echo \"Entering current folder $current_folder\""
}

# ----------------------------------------------------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------------------------------------------------
function nixlper_help() {
  read -rp "Nixlper help, please hit a topic (can be a pattern, for example \"bookma\": " topic_input
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
# ----------------------------------------------------------------------------------------------------------------------
# Bindings
# ----------------------------------------------------------------------------------------------------------------------
function _load_bindings() {
  # bookmarks
  bind -x '"\C-x\C-d": _display_existing_bookmarks'
  bind  '"\C-x\C-b": "_add_or_remove_bookmark\15"'
  # help
  bind '"\C-x\C-h": "nixlper_help\15"'

  # instant access to this file
  bind -x '"\C-x\C-o": vim ${NIXLPER_INSTALL_DIR}/nixlper.sh'
}
# ----------------------------------------------------------------------------------------------------------------------
# Init
# ----------------------------------------------------------------------------------------------------------------------
function _test_prerequisites() {
  if [[ -z ${NIXLPER_INSTALL_DIR} ]]; then
    _log_as_error "NIXLPER_INSTALL_DIR is not defined, please run \"install\" command"
    return 1
  fi
  if [[ -z ${NIXLPER_INSTALL_DIR} ]]; then
    _log_as_error "NIXLPER_BOOKMARKS_FILE is not defined, please run \"install\" command"
    return 1
  fi
}

function _init() {
  _create_bookmarks_file_if_not_existing
  _load_bookmarks
  _load_bindings
}
# ----------------------------------------------------------------------------------------------------------------------
# Install nixlper
# ----------------------------------------------------------------------------------------------------------------------
function _install() {
  touch ~/.bashrc
  if grep "nixlper.sh" ~/.bashrc; then
    _log_as_info ".bashrc has already a reference nixlper, action is skipped"
  else
    _log_as_info "Backup existing .bashrc"
    cp ~/.bashrc ~/.bashrc.ori
    _log_as_info "Update .bashrc with nixlper"
    echo "" >> ~/.bashrc
    echo "################################################################################################" >> ~/.bashrc
    echo "# nilxper installation" >> ~/.bashrc
    echo "################################################################################################" >> ~/.bashrc
    echo "export NIXLPER_INSTALL_DIR=$(pwd)" >> ~/.bashrc
    echo "export NIXLPER_BOOKMARKS_FILE=\${NIXLPER_INSTALL_DIR}/.nixlper_bookmarks" >> ~/.bashrc
    echo "source \${NIXLPER_INSTALL_DIR}/nixlper.sh" >> ~/.bashrc
    echo "################################################################################################" >> ~/.bashrc
    source ~/.bashrc
  fi
}

# **********************************************************************************************************************
# Commands exposed to user
# **********************************************************************************************************************
# ----------------------------------------------------------------------------------------------------------------------
# Folders
# ----------------------------------------------------------------------------------------------------------------------
# Go to folder from a filepath
function cdf() {
    [[ "$1" == "--help" ]] && echo "$FUNCNAME go to the folder containing the provided path

    Usage; $0 PATH" && return 0

    [[ $# -lt 1 ]] && _log_as_error "Please specify a filepath." && return 1
    local -r folderpath=$(dirname "$1")
    cd "${folderpath}" || return 1
    _log_as_info "Now in ${folderpath}"
}
# Set current folder
alias c=_mark_folder_as_current

# **********************************************************************************************************************
# Main part
# **********************************************************************************************************************
function main() {
  if [[ $# -eq 0 ]]; then
    if _test_prerequisites; then
      _init
    fi
  else
    local -r command=$1
    if [[ "${command}" == "install" ]]; then
      _install
    else
      echo "command ${command} is unknown, use one the following ones:
      install: to install NIXLPER"
    fi
  fi
}

main "$@"