#!/usr/bin/env bash
########################################################################################################################
# FILE: bookmarks.sh
# DESCRIPTION: perform all bookmarks actions like in Total Commander (see https://www.ghisler.com/accueil.htm)
########################################################################################################################

#***********************************************************************************************************************
# Constants
#***********************************************************************************************************************
# sed pattern to display a bookmark like "/var/projects (projects_alias)" where "projects_alias" is an alias.
SED_PATTERN_EXTRACT_ALIAS="s/alias (\w+)='cd (\S+)( &&.*)/\2 (\1)/g"

#***********************************************************************************************************************
# Bookmarks mains actions
#***********************************************************************************************************************

#-----------------------------------------------------------------------------------------------------------------------
# _display_existing_bookmarks: display existing bookmarks displaying path + related alias
# @cmd-palette
# @description: Display existing bookmarks with aliases
# @category: Bookmarks
# @keybind: CTRL+X+D
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

#-----------------------------------------------------------------------------------------------------------------------
# _add_or_remove_bookmark: add or remove a bookmark from current directory
#
# Similarly to Total commander (https://www.ghisler.com/accueil.htm) this function behaves like:
# - Display existing bookmarks
# - Test if current folder is in the bookmarks
#   - if so, propose to add it to the bookmarks
#   - if no, propose to remove it from bookmarks
# @cmd-palette
# @description: Add or remove bookmark for current folder
# @category: Bookmarks
# @keybind: CTRL+X+B
#-----------------------------------------------------------------------------------------------------------------------
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

#***********************************************************************************************************************
# Bookmarks atomic actions
#***********************************************************************************************************************
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

function _i_get_matching_bookmark_for_current_folder() {
  local -r matching_bookmark=$(grep "$(pwd) &&" "$NIXLPER_BOOKMARKS_FILE")
  echo "${matching_bookmark}"
}

function _i_get_matching_bookmark_for_alias() {
  local -r matching_bookmark=$(grep " $1=" "$NIXLPER_BOOKMARKS_FILE")
  echo "${matching_bookmark}"
}
