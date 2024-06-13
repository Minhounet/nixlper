#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: help.sh                                                              #
#                                           DESCRIPTION: functions related help                                        #
########################################################################################################################
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
