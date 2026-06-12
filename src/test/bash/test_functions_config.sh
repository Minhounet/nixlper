#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_config.sh
# DESCRIPTION: Unit tests for functions_config.sh (non-interactive helpers only).
#
# fzf-driven and read-driven flows are not tested here — only the pure-bash helpers
# that can run offline in a temp environment: migration detection, config file
# read/write, and metadata lookups.
# Run locally with: bash src/test/bash/test_functions_config.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_config.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Isolated temp environment — override HOME so no real files are touched
_TEST_DIR="$(mktemp -d)"
export HOME="${_TEST_DIR}/home"
mkdir -p "${HOME}/.config/nixlper"
trap 'rm -rf "${_TEST_DIR}"' EXIT

export NIXLPER_INSTALL_DIR="${_TEST_DIR}/install"
mkdir -p "${NIXLPER_INSTALL_DIR}"

# shellcheck source=/dev/null
source "${MODULE}"

# _NIXLPER_USER_CONF was set during source using $HOME (already the temp dir)

#-----------------------------------------------------------------------------------------------------------------------
PASS=0
FAIL=0

_expect_eq() {
  local -r name="$1" got="$2" want="$3"
  if [[ "${got}" == "${want}" ]]; then
    echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: got [${got}] want [${want}]"; FAIL=$((FAIL + 1))
  fi
}

_expect_true() {
  local -r name="$1"; shift
  if "$@"; then echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else echo "  ❌ ${name}: expected success"; FAIL=$((FAIL + 1)); fi
}

_expect_false() {
  local -r name="$1"; shift
  if "$@"; then echo "  ❌ ${name}: expected failure"; FAIL=$((FAIL + 1))
  else echo "  ✅ ${name}"; PASS=$((PASS + 1)); fi
}

_file_exists()     { [[ -f "$1" ]]; }
_file_contains()   { grep -q "$2" "$1" 2>/dev/null; }
_file_not_exists() { [[ ! -f "$1" ]]; }

_reset_conf()   { rm -f "${_NIXLPER_USER_CONF}"; }
_reset_bashrc() { rm -f "${HOME}/.bashrc"; touch "${HOME}/.bashrc"; }

#-----------------------------------------------------------------------------------------------------------------------
echo "== _nconf_migration_needed =="
_reset_bashrc
_expect_false "no NIXLPER_ lines → not needed"     _nconf_migration_needed
echo "export NIXLPER_EDITOR=nano"  >> "${HOME}/.bashrc"
_expect_true  "has NIXLPER_ export → needed"       _nconf_migration_needed
echo "# comment"                   >> "${HOME}/.bashrc"
_expect_true  "still needed with extra lines"      _nconf_migration_needed
_reset_bashrc
echo "export OTHER_VAR=foo"        >> "${HOME}/.bashrc"
_expect_false "non-NIXLPER export → not needed"    _nconf_migration_needed

#-----------------------------------------------------------------------------------------------------------------------
echo "== _nconf_ensure_config_file =="
_reset_conf
_expect_true  "conf absent before ensure"          _file_not_exists "${_NIXLPER_USER_CONF}"
_nconf_ensure_config_file
_expect_true  "conf created after ensure"          _file_exists    "${_NIXLPER_USER_CONF}"
_expect_true  "conf not empty"                     _file_contains  "${_NIXLPER_USER_CONF}" "nixlper"
# Calling again must not overwrite
echo "custom_marker" >> "${_NIXLPER_USER_CONF}"
_nconf_ensure_config_file
_expect_true  "ensure is idempotent"               _file_contains  "${_NIXLPER_USER_CONF}" "custom_marker"

#-----------------------------------------------------------------------------------------------------------------------
echo "== _nconf_write_setting =="
_reset_conf

_nconf_write_setting "NIXLPER_EDITOR" "nano" "vim"
_expect_true  "non-default value written"          _file_contains  "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=nano"

_nconf_write_setting "NIXLPER_EDITOR" "emacs" "vim"
_expect_true  "value updated in-place"             _file_contains  "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=emacs"
_expect_eq    "only one EDITOR line"               "$(grep -c 'NIXLPER_EDITOR' "${_NIXLPER_USER_CONF}")" "1"

_nconf_write_setting "NIXLPER_EDITOR" "vim" "vim"
_expect_false "default value removes override"     _file_contains  "${_NIXLPER_USER_CONF}" "NIXLPER_EDITOR"

_nconf_write_setting "NIXLPER_NAVIGATE_MODE" "flat" "tree"
_nconf_write_setting "NIXLPER_UPDATE_TIMEOUT" "5" "2"
_expect_true  "second var written"                 _file_contains  "${_NIXLPER_USER_CONF}" "export NIXLPER_NAVIGATE_MODE=flat"
_expect_true  "third var written"                  _file_contains  "${_NIXLPER_USER_CONF}" "export NIXLPER_UPDATE_TIMEOUT=5"

# Empty default: always write (no removal)
_nconf_write_setting "NIXLPER_BOOKMARKS_FILE" "/custom/path" ""
_expect_true  "empty-default var written"          _file_contains  "${_NIXLPER_USER_CONF}" "export NIXLPER_BOOKMARKS_FILE=/custom/path"

# Bug 1 regression: special characters in value must not corrupt the config file
_reset_conf
_nconf_write_setting "NIXLPER_EDITOR" "/usr/bin/vi" "vim"
_nconf_write_setting "NIXLPER_EDITOR" "/opt/my|editor" "vim"
_expect_true  "pipe char in value written correctly"   _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=/opt/my|editor"
_expect_eq    "no extra lines after pipe update"       "$(grep -c 'NIXLPER_EDITOR' "${_NIXLPER_USER_CONF}")" "1"

_reset_conf
_nconf_write_setting "NIXLPER_EDITOR" "/usr/bin/vi" "vim"
_nconf_write_setting "NIXLPER_EDITOR" "/opt/my&editor" "vim"
_expect_true  "ampersand in value written correctly"   _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=/opt/my&editor"
_expect_eq    "no extra lines after ampersand update"  "$(grep -c 'NIXLPER_EDITOR' "${_NIXLPER_USER_CONF}")" "1"

_reset_conf
_nconf_write_setting "NIXLPER_EDITOR" "/usr/bin/vi" "vim"
_nconf_write_setting "NIXLPER_EDITOR" "/opt/back\\slash" "vim"
_expect_true  "backslash in value written correctly"   _file_contains "${_NIXLPER_USER_CONF}" 'NIXLPER_EDITOR'

#-----------------------------------------------------------------------------------------------------------------------
echo "== _nconf_get_meta =="
_nconf_get_meta "NIXLPER_EDITOR"
_expect_eq "editor type"            "$_nconf_type"    "text"
_expect_eq "editor default"         "$_nconf_default" "vim"

_nconf_get_meta "NIXLPER_NAVIGATE_MODE"
_expect_eq "navigate type"          "$_nconf_type"    "enum:tree:flat"
_expect_eq "navigate default"       "$_nconf_default" "tree"

_nconf_get_meta "NIXLPER_UPDATE_CHANNEL"
_expect_eq "channel type"           "$_nconf_type"    "enum:stable:edge:off"
_expect_eq "channel section"        "$_nconf_section" "common"

_nconf_get_meta "NIXLPER_UPDATE_CHECK_INTERVAL"
_expect_eq "interval type"          "$_nconf_type"    "int"
_expect_eq "interval section"       "$_nconf_section" "advanced"

_nconf_get_meta "NIXLPER_DISABLE_WELCOME_MESSAGE"
_expect_eq "bool type"              "$_nconf_type"    "bool"
_expect_eq "bool default"           "$_nconf_default" "false"

_expect_false "unknown var returns error"           _nconf_get_meta "NIXLPER_NONEXISTENT"

#-----------------------------------------------------------------------------------------------------------------------
echo "== _nconf_create_user_conf =="
_reset_conf
_nconf_create_user_conf "/opt/nixlper"
_expect_true  "conf created"                       _file_exists   "${_NIXLPER_USER_CONF}"
_expect_true  "INSTALL_DIR written"                _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_INSTALL_DIR=/opt/nixlper"
_expect_true  "editor commented out"               _file_contains "${_NIXLPER_USER_CONF}" "# export NIXLPER_EDITOR=vim"
# Idempotent — calling again must not overwrite
echo "my_marker" >> "${_NIXLPER_USER_CONF}"
_nconf_create_user_conf "/opt/nixlper"
_expect_true  "create is idempotent"               _file_contains "${_NIXLPER_USER_CONF}" "my_marker"

#-----------------------------------------------------------------------------------------------------------------------
echo "== _nconf_do_migrate =="
_reset_conf
_reset_bashrc
cat > "${HOME}/.bashrc" << 'BASHRC'
# user content
export NIXLPER_INSTALL_DIR=/opt/nixlper
export NIXLPER_EDITOR=nano
export NIXLPER_UPDATE_CHANNEL=edge
source ${NIXLPER_INSTALL_DIR}/nixlper.sh
# end user content
BASHRC

export NIXLPER_INSTALL_DIR=/opt/nixlper
local_backup="${HOME}/.bashrc.nixlper-backup-test"
_nconf_do_migrate "$local_backup"

_expect_true  "backup created"                     _file_exists   "$local_backup"
_expect_true  "conf created"                       _file_exists   "${_NIXLPER_USER_CONF}"
_expect_true  "INSTALL_DIR in conf"                _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_INSTALL_DIR=/opt/nixlper"
_expect_true  "EDITOR in conf"                     _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=nano"
_expect_true  "CHANNEL in conf"                    _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_UPDATE_CHANNEL=edge"
_expect_false "NIXLPER_ vars gone from bashrc"     _file_contains "${HOME}/.bashrc" "^export NIXLPER_"
_expect_true  "user content preserved"             _file_contains "${HOME}/.bashrc" "# user content"
_expect_true  "source line hardened"               _file_contains "${HOME}/.bashrc" "source /opt/nixlper/nixlper.sh"
_expect_false "variable source line removed"       _file_contains "${HOME}/.bashrc" 'source ${NIXLPER_INSTALL_DIR}'

# Bug 3 regression: second migration must not overwrite nconf-edited values in the config file
# Simulate: user ran nconf and changed NIXLPER_EDITOR to emacs in the config file,
# then runs nconf again (which triggers migration again because .bashrc still has NIXLPER_EDITOR=nano).
# The config file value (emacs) must win over the .bashrc value (nano).
_reset_bashrc
cat > "${HOME}/.bashrc" << 'BASHRC'
export NIXLPER_EDITOR=nano
export NIXLPER_UPDATE_CHANNEL=edge
source /opt/nixlper/nixlper.sh
BASHRC
# Config file already exists with a user edit
mkdir -p "${HOME}/.config/nixlper"
printf "export NIXLPER_EDITOR=emacs\n" > "${_NIXLPER_USER_CONF}"

local_backup2="${HOME}/.bashrc.nixlper-backup-test2"
_nconf_do_migrate "$local_backup2"

_expect_true  "conf-file value (emacs) survives second migration" \
              _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=emacs"
_expect_false "bashrc value (nano) does not overwrite conf-file"  \
              _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_EDITOR=nano"
_expect_true  "bashrc-only var (CHANNEL) still imported"          \
              _file_contains "${_NIXLPER_USER_CONF}" "export NIXLPER_UPDATE_CHANNEL=edge"

#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "====================================================================================================="
echo "RESULT: ${PASS} passed, ${FAIL} failed"
echo "====================================================================================================="
[[ ${FAIL} -eq 0 ]]
