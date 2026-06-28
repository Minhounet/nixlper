#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_config.sh
# DESCRIPTION: Interactive configuration editor — nconf manages ~/.config/nixlper/nixlper.conf
########################################################################################################################

_NIXLPER_USER_CONF="${HOME}/.config/nixlper/nixlper.conf"

# Registry: "NAME|TYPE|DEFAULT|DESCRIPTION|SECTION"
# TYPE: bool | enum:v1:v2:... | int | text | path
_NIXLPER_CONFIG_VARS=(
  "NIXLPER_EDITOR|text|vim|Text editor for file commands|common"
  "NIXLPER_NAVIGATE_MODE|enum:tree:flat|tree|Navigation display mode|common"
  "NIXLPER_DISABLE_WELCOME_MESSAGE|bool|false|Suppress startup banner at login|common"
  "NIXLPER_DISABLE_TIPS|bool|false|Suppress tips at login|common"
  "NIXLPER_JOKE_LANG|enum:auto:fr:en|auto|Joke language (auto detects from \$LANG)|common"
  "NIXLPER_UPDATE_CHECK|bool|true|Auto-check for updates at login|common"
  "NIXLPER_UPDATE_AUTO|bool|false|Auto-install detected updates|common"
  "NIXLPER_UPDATE_CHANNEL|enum:stable:edge:off|stable|Update channel|common"
  "NIXLPER_TARGET_DIR|path|/tmp/nixlper_target|Staging folder for copy/mark/pack|common"
  "NIXLPER_UPDATE_CHECK_INTERVAL|int|86400|Seconds between auto-checks|advanced"
  "NIXLPER_UPDATE_TIMEOUT|int|2|Network probe timeout (seconds)|advanced"
  "NIXLPER_BOOKMARKS_FILE|path||Bookmarks file path|advanced"
  "NIXLPER_SNAPSHOT_DIR|path||Snapshots directory|advanced"
  "NIXLPER_CUSTOM_DIR|path||Custom scripts directory|advanced"
  "NIXLPER_LAST_MACRO_BINDING_FILE|path||Last macro binding file|advanced"
  "NIXLPER_UPDATE_CACHE_FILE|path||Update check cache file|advanced"
  "NIXLPER_SSH_CONNECTIONS_FILE|path||SSH connections file (default: ~/.config/nixlper/ssh_connections)|advanced"
  "NIXLPER_SSH_IDENTITY_FILE|path||Default SSH identity file for nixlper connections|advanced"
  "NIXLPER_RECENT_DIRS_MAX|int|20|Maximum number of recent directories to remember|common"
  "NIXLPER_RECENT_DIRS_FILE|path||Recent directories history file|advanced"
)

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_migration_needed: true if ~/.bashrc still has export NIXLPER_* lines
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_migration_needed() {
  [[ -f "${HOME}/.bashrc" ]] && grep -q "^export NIXLPER_" "${HOME}/.bashrc" 2>/dev/null
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_show_recovery_help: print recovery instructions
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_show_recovery_help() {
  local -r backup="${1:-}"
  echo ""
  echo "── Recovery ─────────────────────────────────────────────────────────────────"
  [[ -n "$backup" ]] && printf "  Restore .bashrc : cp %s ~/.bashrc\n" "$backup"
  echo "  Clean reinstall via RPM : bash nixlper.sh uninstall && dnf install nixlper-*.rpm"
  echo "  Clean reinstall via DEB : bash nixlper.sh uninstall && dpkg -i nixlper-*.deb"
  echo "  Report issues : https://github.com/Minhounet/nixlper/issues"
  echo "─────────────────────────────────────────────────────────────────────────────"
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_do_migrate: write config file from .bashrc vars, then clean .bashrc
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_do_migrate() {
  local -r backup="$1"

  echo "Step 1/3: Backing up ~/.bashrc → ${backup##*/}"
  cp "${HOME}/.bashrc" "$backup" || { echo "ERROR: Backup failed. Aborting."; return 1; }

  echo "Step 2/3: Writing ${_NIXLPER_USER_CONF}"
  mkdir -p "${HOME}/.config/nixlper"
  # Merge: existing config vars take priority; .bashrc vars fill in any that are missing.
  local -a existing_vars=()
  if [[ -f "${_NIXLPER_USER_CONF}" ]]; then
    while IFS= read -r line; do
      existing_vars+=("$line")
    done < <(grep "^export NIXLPER_" "${_NIXLPER_USER_CONF}" 2>/dev/null)
  fi
  local tmp_conf
  tmp_conf=$(mktemp)
  {
    printf "# nixlper user configuration — migrated from ~/.bashrc on %s\n" "$(date)"
    printf "# Edit interactively: nconf\n\n"
    # Existing config file entries (highest priority)
    printf '%s\n' "${existing_vars[@]+"${existing_vars[@]}"}"
    # .bashrc entries not already present in the config file
    while IFS= read -r line; do
      local bvar="${line#export }"
      bvar="${bvar%%=*}"
      if ! printf '%s\n' "${existing_vars[@]+"${existing_vars[@]}"}" | grep -q "^export ${bvar}="; then
        printf '%s\n' "$line"
      fi
    done < <(grep "^export NIXLPER_" "${HOME}/.bashrc" 2>/dev/null)
  } > "$tmp_conf"

  if ! bash -n "$tmp_conf" 2>/dev/null; then
    echo "ERROR: Config file has syntax errors. Aborting — no files modified."
    rm -f "$tmp_conf"
    _nconf_show_recovery_help "$backup"
    return 1
  fi
  mv "$tmp_conf" "${_NIXLPER_USER_CONF}"

  echo "Step 3/3: Cleaning ~/.bashrc"
  # Replace ${NIXLPER_INSTALL_DIR}/nixlper.sh source line with the actual path so
  # .bashrc no longer depends on NIXLPER_INSTALL_DIR being set before the source call.
  if [[ -n "${NIXLPER_INSTALL_DIR:-}" ]]; then
    sed -i "s|source \${NIXLPER_INSTALL_DIR}/nixlper\.sh|source ${NIXLPER_INSTALL_DIR}/nixlper.sh|g" \
      "${HOME}/.bashrc"
  fi
  sed -i "/^export NIXLPER_/d" "${HOME}/.bashrc"

  echo ""
  echo "✓ Migration complete."
  printf "  Config : %s\n" "${_NIXLPER_USER_CONF}"
  printf "  Backup : %s\n" "$backup"
  echo ""
  echo "Run: source ~/.bashrc  to apply in the current shell."
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_prompt_migration: explain migration and ask user to confirm
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_prompt_migration() {
  local var_count
  var_count=$(grep -c "^export NIXLPER_" "${HOME}/.bashrc" 2>/dev/null || echo 0)
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local -r backup="${HOME}/.bashrc.nixlper-backup-${ts}"

  echo "────────────────────────────────────────────────────────────────────────────"
  echo "nixlper config — migration available"
  echo "────────────────────────────────────────────────────────────────────────────"
  printf "  %s nixlper variable(s) found in ~/.bashrc.\n" "$var_count"
  echo "  nixlper now uses ~/.config/nixlper/nixlper.conf for all settings,"
  echo "  keeping ~/.bashrc to just the source line."
  echo ""
  echo "  Migration will:"
  printf "    1. Back up ~/.bashrc  →  %s\n" "${backup##*/}"
  echo "    2. Write your settings to ~/.config/nixlper/nixlper.conf"
  echo "    3. Remove nixlper variables from ~/.bashrc (keep source line)"
  echo "────────────────────────────────────────────────────────────────────────────"
  echo -n "Migrate now? [y/N]: "
  read -r answer

  case "$answer" in
    y|Y) _nconf_do_migrate "$backup" ;;
    *)   echo "Skipped. Your ~/.bashrc is unchanged. You will be prompted again next time." ;;
  esac
  echo ""
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_ensure_config_file: create ~/.config/nixlper/nixlper.conf if it does not exist
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_ensure_config_file() {
  [[ -f "${_NIXLPER_USER_CONF}" ]] && return 0
  mkdir -p "${HOME}/.config/nixlper"
  {
    printf "# nixlper user configuration — edit with: nconf\n"
    printf "# Only non-default values need to be set here.\n\n"
    [[ -n "${NIXLPER_INSTALL_DIR:-}" ]] && printf "export NIXLPER_INSTALL_DIR=%s\n" "${NIXLPER_INSTALL_DIR}"
  } > "${_NIXLPER_USER_CONF}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_create_user_conf: create a documented config file template at install time
# $1 = install_dir
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_create_user_conf() {
  local -r install_dir="${1}"
  [[ -f "${_NIXLPER_USER_CONF}" ]] && return 0
  mkdir -p "${HOME}/.config/nixlper"
  {
    printf "# nixlper user configuration\n"
    printf "# Edit interactively: nconf  |  or edit this file directly.\n"
    printf "# Only lines that differ from defaults need to be uncommented.\n\n"
    printf "export NIXLPER_INSTALL_DIR=%s\n\n" "${install_dir}"
    printf "# --- Common settings ---\n"
    printf "# export NIXLPER_EDITOR=vim\n"
    printf "# export NIXLPER_NAVIGATE_MODE=tree\n"
    printf "# export NIXLPER_DISABLE_WELCOME_MESSAGE=false\n"
    printf "# export NIXLPER_DISABLE_TIPS=false\n"
    printf "# export NIXLPER_JOKE_LANG=auto\n"
    printf "# export NIXLPER_UPDATE_CHECK=true\n"
    printf "# export NIXLPER_UPDATE_AUTO=false\n"
    printf "# export NIXLPER_UPDATE_CHANNEL=stable\n"
    printf "# export NIXLPER_TARGET_DIR=/tmp/nixlper_target\n\n"
    printf "# --- Advanced settings ---\n"
    printf "# export NIXLPER_UPDATE_CHECK_INTERVAL=86400\n"
    printf "# export NIXLPER_UPDATE_TIMEOUT=2\n"
    printf "# export NIXLPER_RECENT_DIRS_MAX=20\n"
    printf "# export NIXLPER_BOOKMARKS_FILE=\${HOME}/.local/share/nixlper/bookmarks\n"
    printf "# export NIXLPER_SNAPSHOT_DIR=\${HOME}/.local/share/nixlper/snapshots\n"
    printf "# export NIXLPER_CUSTOM_DIR=\${HOME}/.config/nixlper/custom\n"
    printf "# export NIXLPER_LAST_MACRO_BINDING_FILE=\${HOME}/.local/share/nixlper/last_macro_binding\n"
    printf "# export NIXLPER_UPDATE_CACHE_FILE=\${HOME}/.local/share/nixlper/update_check\n"
    printf "# export NIXLPER_RECENT_DIRS_FILE=\${HOME}/.local/share/nixlper/recent_dirs\n"
  } > "${_NIXLPER_USER_CONF}"
  echo "  -> Created ${_NIXLPER_USER_CONF}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_write_setting: write or remove a variable override in the user config file
# $1 = varname, $2 = new value, $3 = default value
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_write_setting() {
  local -r varname="$1" new_val="$2" default="$3"

  _nconf_ensure_config_file

  if [[ "$new_val" == "$default" && -n "$default" ]]; then
    # Value equals default — remove any override so the default applies naturally
    sed -i "/^export ${varname}=/d" "${_NIXLPER_USER_CONF}"
    printf "Reset %s to default (%s).\n" "$varname" "$default"
  else
    if grep -q "^export ${varname}=" "${_NIXLPER_USER_CONF}" 2>/dev/null; then
      local escaped_val
      escaped_val=$(printf '%s' "$new_val" | sed 's/[\\&|]/\\&/g')
      sed -i "s|^export ${varname}=.*|export ${varname}=${escaped_val}|" "${_NIXLPER_USER_CONF}"
    else
      printf "export %s=%s\n" "$varname" "$new_val" >> "${_NIXLPER_USER_CONF}"
    fi
    printf "Set %s=%s\n" "$varname" "$new_val"
  fi
  # Reflect change in the current session immediately
  export "${varname}=${new_val}"
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_get_meta: populate type/default/desc/section for a given varname
# Sets: _nconf_type, _nconf_default, _nconf_desc, _nconf_section
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_get_meta() {
  local -r target="$1"
  _nconf_type="" _nconf_default="" _nconf_desc="" _nconf_section=""
  local entry n
  for entry in "${_NIXLPER_CONFIG_VARS[@]}"; do
    n=$(cut -d'|' -f1 <<< "$entry")
    if [[ "$n" == "$target" ]]; then
      _nconf_type=$(cut    -d'|' -f2 <<< "$entry")
      _nconf_default=$(cut -d'|' -f3 <<< "$entry")
      _nconf_desc=$(cut    -d'|' -f4 <<< "$entry")
      _nconf_section=$(cut -d'|' -f5 <<< "$entry")
      return 0
    fi
  done
  return 1
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_edit_variable: type-aware value picker for a single variable
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_edit_variable() {
  local -r varname="$1"
  _nconf_get_meta "$varname" || return 1

  local type="$_nconf_type"
  local default="$_nconf_default"
  local desc="$_nconf_desc"
  local current="${!varname}"
  [[ -z "$current" ]] && current="$default"

  local new_val=""

  if [[ "$type" == "bool" ]]; then
    new_val=$(printf "true\nfalse\n" | fzf \
      --height=7 --border=rounded --no-sort \
      --prompt="${varname} > " \
      --header="${desc} | current: ${current}" \
      --color="header:cyan,prompt:green,pointer:yellow")

  elif [[ "$type" == enum:* ]]; then
    local opts_str="${type#enum:}"
    local -a opts
    IFS=':' read -ra opts <<< "$opts_str"
    new_val=$(printf '%s\n' "${opts[@]}" | fzf \
      --height="$(( ${#opts[@]} + 5 ))" --border=rounded --no-sort \
      --prompt="${varname} > " \
      --header="${desc} | current: ${current}" \
      --color="header:cyan,prompt:green,pointer:yellow")

  elif [[ "$type" == "int" ]]; then
    printf "%s\nCurrent: %s  (default: %s)\n" "$desc" "$current" "${default:-n/a}"
    local input
    read -r -e -p "${varname} [${current}]: " -i "${current}" input
    new_val="${input:-$current}"
    if ! [[ "$new_val" =~ ^[0-9]+$ ]]; then
      printf "Invalid integer '%s' — keeping current value.\n" "$new_val"
      return 0
    fi

  else  # text or path
    printf "%s\nCurrent: %s  (default: %s)\n" "$desc" "$current" "${default:-n/a}"
    local input
    read -r -e -p "${varname} [${current}]: " -i "${current}" input
    new_val="${input:-$current}"
    [[ -z "$new_val" ]] && return 0
  fi

  [[ -z "$new_val" ]] && return 0
  _nconf_write_setting "$varname" "$new_val" "$default"
}

#-----------------------------------------------------------------------------------------------------------------------
# _nconf_build_fzf_input: emit tab-delimited lines: VARNAME<TAB>display_text
# Separator lines use __sep__ as the key.
#-----------------------------------------------------------------------------------------------------------------------
function _nconf_build_fzf_input() {
  local prev_section="common"
  local entry varname type default desc section current indicator

  for entry in "${_NIXLPER_CONFIG_VARS[@]}"; do
    varname=$(cut  -d'|' -f1 <<< "$entry")
    type=$(cut     -d'|' -f2 <<< "$entry")
    default=$(cut  -d'|' -f3 <<< "$entry")
    desc=$(cut     -d'|' -f4 <<< "$entry")
    section=$(cut  -d'|' -f5 <<< "$entry")

    if [[ "$section" == "advanced" && "$prev_section" == "common" ]]; then
      prev_section="advanced"
      printf '__sep__\t  %-3s  %-44s  %-24s  %s\n' "" \
        "──── Advanced settings ─────────────────────" "" ""
    fi

    current="${!varname}"
    [[ -z "$current" ]] && current="$default"

    if grep -q "^export ${varname}=" "${_NIXLPER_USER_CONF}" 2>/dev/null; then
      indicator="*"
    else
      indicator=" "
    fi

    printf '%s\t  [%s] %-44s  %-24s  %s\n' \
      "$varname" "$indicator" "$varname" "$current" "$desc"
  done
}

#-----------------------------------------------------------------------------------------------------------------------
# nconf: interactive configuration editor
# @cmd-palette
# @description: Open interactive configuration editor
# @category: Utilities
# @keybind: CTRL+X+C
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function nconf() {
  if ! command -v fzf &>/dev/null; then
    printf "nconf requires fzf. Install it or edit %s directly.\n" "${_NIXLPER_USER_CONF}"
    return 1
  fi

  if _nconf_migration_needed; then
    _nconf_prompt_migration
  fi

  _nconf_ensure_config_file

  local selection varname
  while true; do
    selection=$(_nconf_build_fzf_input | fzf \
      --delimiter=$'\t' \
      --with-nth=2 \
      --ansi \
      --height=80% \
      --border=rounded \
      --prompt="nixlper config > " \
      --header="[*]=overridden from default  |  Enter=edit  |  ESC=close" \
      --color="header:cyan,prompt:green,pointer:yellow")

    [[ -z "$selection" ]] && break

    varname=$(cut -f1 <<< "$selection")
    [[ "$varname" == "__sep__" || -z "$varname" ]] && continue

    echo ""
    _nconf_edit_variable "$varname"
    echo ""
  done

  printf "\nConfig file: %s\n" "${_NIXLPER_USER_CONF}"
  echo "Open a new terminal (or run: source ~/.bashrc) to apply changes."
}
