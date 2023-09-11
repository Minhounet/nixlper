#!/usr/bin/env bash

export NIXLPER_INSTALL_DIR
NIXLPER_INSTALL_DIR="$(dirname "${BASH_SOURCE[0]}")"
export NIXLPER_BOOKMARKS_FILE=${NIXLPER_INSTALL_DIR}/.nixlper_bookmarks
# ----------------------------------------------------------------------------------------------------------------------
# dev utils
# ----------------------------------------------------------------------------------------------------------------------
function debug_display_variables() {
    echo "Install dir NIXLPER_INSTALL_DIR is ${NIXLPER_INSTALL_DIR}"
}
# ----------------------------------------------------------------------------------------------------------------------
# Init part
# ----------------------------------------------------------------------------------------------------------------------
function init() {
  create_bookmarks_file_if_not_existing
}
# ----------------------------------------------------------------------------------------------------------------------
# Bookmarks part
# ----------------------------------------------------------------------------------------------------------------------
function create_bookmarks_file_if_not_existing() {
  if [[ ! -f $NIXLPER_BOOKMARKS_FILE ]]; then
    echo "Bookmarks file does not exist, create ${NIXLPER_BOOKMARKS_FILE}"
    touch "${NIXLPER_BOOKMARKS_FILE}"
    chmod 777 "${NIXLPER_BOOKMARKS_FILE}"
  fi
}

# Bookmark a directory to a specific file. An alias is used to define the bookmark.
function bookmark_directory() {
  [[ "$1" == "--help" ]] && echo "$FUNCNAME bookmark a specific directory storing its path into a file with a specific alias.
    Thus it is possible to reach this folder using an alias.

    Usage: $0 SHORTCUT_NAME DIR_TO_BOOKMARK

    SHORTCUT_NAME: the name or the alias.
    DIR_TO_BOOKMARK: the directory to bookmark" && return 0

  local -r shortcut_name=$1
  local -r bookmarked_dir=$2

  [[ $# -ne 2 ]] && log_as_error "Please specify the bookmarks, the shortcut name and the bookmarked dir." && return 1

  # Only bookmark if not existing.
  [[ $(grep "alias ${shortcut_name}=" ${NIXLPER_BOOKMARKS_FILE}) ]] || echo "alias $shortcut_name='cd $bookmarked_dir && echo \"INFO: Jump into folder $(pwd)\"'" >> "${NIXLPER_BOOKMARKS_FILE}"
}
# ----------------------------------------------------------------------------------------------------------------------
# Logger part
# ----------------------------------------------------------------------------------------------------------------------
function _log() {
  local -r category=$1
  local message=${@:2}
  local -r date=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${date} ${category} ${message}"
}

function log_as_error() {
  _log "ERROR" $@
}
# ----------------------------------------------------------------------------------------------------------------------
# Main part
# ----------------------------------------------------------------------------------------------------------------------
function main() {
    init
}

main