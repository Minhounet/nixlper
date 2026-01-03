#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: nixlper.sh                                                           #
#                                           DESCRIPTION: the bash helper in an linux environment                       #
########################################################################################################################

#***********************************************************************************************************************
# INITIALIZATION
#***********************************************************************************************************************
#-----------------------------------------------------------------------------------------------------------------------
# General initialization
#-----------------------------------------------------------------------------------------------------------------------
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
    local -r script_template_path="${custom_dir}/script_template.sh"
    touch "${script_template_path}"
    echo "alias iversion=\"cat ${NIXLPER_INSTALL_DIR}/version\"" > "${script_template_path}"
  fi
}

function _i_create_snapshot_folder() {
  local -r snapshot_dir=${NIXLPER_INSTALL_DIR}/snapshots
  if [[ ! -d "${snapshot_dir}" ]] ; then
    echo "Snapshots directory does not exist, create it"
    mkdir -p "${snapshot_dir}"
  fi
}
#-----------------------------------------------------------------------------------------------------------------------

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
  echo "export NIXLPER_LAST_MACRO_BINDING_FILE=\${NIXLPER_INSTALL_DIR}/.nixlper_last_macro_binding_file" >> ~/.bashrc
  echo "export NIXLPER_NAVIGATE_MODE=tree" >> ~/.bashrc
  echo "export NIXLPER_EDITOR=vim" >> ~/.bashrc
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
# BINDINGS
#***********************************************************************************************************************
function _i_load_bindings() {
  if [[ $- == *i* ]]; then
    # bookmarks
    bind -x '"\C-x\C-d": _display_existing_bookmarks'
    bind  '"\C-x\C-b": "_add_or_remove_bookmark\15"'
    # help
    bind '"\C-x\C-h": "_help\15"'

    # version and logo
    bind -x '"\C-x\C-v": _display_logo_and_version'

    # files
    bind '"\C-x\C-e":"rm -rf $(pwd)/\33\5 && cd .."' #\33\5 is ESC then CTRL+E
    bind '"\C-x\C-r":"rm -rf $(pwd)/\33\5*"' #\33\5 is ESC then CTRL+R

    # navigation
    bind '"\C-x\C-u": "cd ..\15"'
    bind -x '"\C-x\C-n": navigate'

    # instant access to this file
    bind -x '"\C-x\C-o": $NIXLPER_EDITOR ${NIXLPER_INSTALL_DIR}/nixlper.sh'

    bind -x '"\C-p":start_recording'
    bind -x  '"\C-p\C-p": finalize_recording'
    bind -x  '"\C-p\C-l": bind_last_macro'
  fi
}

#***********************************************************************************************************************

#***********************************************************************************************************************
# ALIASES
#***********************************************************************************************************************
alias c=_mark_folder_as_current
alias cdf=_change_directory_from_filepath
alias cf=_mark_file_as_current
alias cpcb=_copy_fullpath_to_clipboard
alias ik=_interactive_kill
alias sucd=_su_to_current_directory
alias sn=_snapshot_file
alias re=_restore_file
alias fan=_find_and_navigate
# Prepend current path in PATH variable updating the .bashrc if not already done
alias ap='DIR=$(pwd); if ! grep -q "$DIR" ~/.bashrc; then echo "export PATH=$DIR:\$PATH" >> ~/.bashrc && echo "Prepended $DIR to PATH in .bashrc"; else echo "$DIR is already in .bashrc"; fi; source ~/.bashrc'
alias sr=start_recording
alias fr=finalize_recording

#***********************************************************************************************************************
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
