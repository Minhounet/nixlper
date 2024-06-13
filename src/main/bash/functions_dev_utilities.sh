#!/usr/bin/env bash
########################################################################################################################
# FILE: dev_utilities.sh
# DESCRIPTION: use only for dev purpose
########################################################################################################################
function TODO() {
  if [[ $# -eq 0 ]]; then
    echo "TODO: there is something to do but what? :)"
  else
    echo "TODO: $*"
  fi
  return 1
}
