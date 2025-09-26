#!/usr/bin/env bash
########################################################################################################################
# FILE: help.sh
# DESCRIPTION: functions related to user help.
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _help: look for help from a pattern (you can look for "book" for bookmarks topic for example
#-----------------------------------------------------------------------------------------------------------------------
function _help() {
  echo "Nixlper Help: existing topics are:"
  ls "${NIXLPER_INSTALL_DIR}"/help | sed 's/help_/- /g' | sed 's/_/ /g'
  read -rp "Please enter a value (can be a pattern, for example \"bookm\"): " topic_input
  topic_input=${topic_input:-""}

  if [[ -z ${topic_input} ]]; then
    less "${NIXLPER_INSTALL_DIR}"/help/help_*
    return
  fi

  echo "Searching for content matching: ${topic_input}"

  # First: search inside file contents
  content_matches=$(grep -iHn "${topic_input}" "${NIXLPER_INSTALL_DIR}"/help/help_* 2>/dev/null)

  if [[ -n "$content_matches" ]]; then
    selected=$(echo "$content_matches" | fzf --ansi --preview 'echo {}' --height=40%)
    if [[ -n "$selected" ]]; then
      file=$(echo "$selected" | cut -d: -f1)
      line=$(echo "$selected" | cut -d: -f2)
      less +${line} "$file"
    fi
    return
  fi

  echo "No content match found. Searching filenames..."

  # Second: search filenames
  file_matches=$(find "${NIXLPER_INSTALL_DIR}/help" -type f -iname "*${topic_input}*")

  if [[ -n "$file_matches" ]]; then
    selected_file=$(echo "$file_matches" | fzf --preview 'cat {}' --height=40%)
    if [[ -n "$selected_file" ]]; then
      less "$selected_file"
    fi
  else
    echo "No topic found for '${topic_input}' in content or filenames."
  fi
}

