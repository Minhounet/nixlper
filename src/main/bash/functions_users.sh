#!/usr/bin/env bash
########################################################################################################################
# FILE: users.sh
# DESCRIPTION: functions related to users
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _su_to_current_directory: perform su - USER in current directory to avoid su - USER then cd PATH
# @cmd-palette
# @description: Switch user and maintain current directory
# @category: Users
# @alias: sucd
#-----------------------------------------------------------------------------------------------------------------------
function _su_to_current_directory() {
  local -r su_user=$1
  su -l -s /bin/bash -c "cd $PWD; script -q /dev/null" ${su_user}
}
