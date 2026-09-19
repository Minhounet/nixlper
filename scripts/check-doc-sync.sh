#!/usr/bin/env bash
########################################################################################################################
# FILE: check-doc-sync.sh
# DESCRIPTION: Verify every @cmd-palette command's name/alias and keybind is documented in its
#              in-shell help file (src/main/help/help_<slug>), its English doc page
#              (docs/feature-<slug>.md) and its French doc page (docs/fr/feature-<slug>.md).
#
# This does NOT check that the prose is in sync — only that the fact ("this command/alias/
# keybind exists") is present wherever a matching doc file exists. It exists to catch the
# recurring bug the tri-location documentation rule guards against: a command added in code
# but never mentioned in one of the docs. See "Tri-location documentation rule" in CLAUDE.md.
########################################################################################################################
set -o nounset
set -o pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CURRENT_DIR
readonly BASH_SRC_DIR="${CURRENT_DIR}/src/main/bash"
readonly HELP_DIR="${CURRENT_DIR}/src/main/help"
readonly DOCS_DIR="${CURRENT_DIR}/docs"
readonly DOCS_FR_DIR="${CURRENT_DIR}/docs/fr"

#***********************************************************************************************************************
# Slug overrides
#
# The default slug is derived from a command's @category (lowercased, "&" dropped, spaces
# collapsed to "_" for help files / "-" for doc pages). That works for most commands, but a
# handful of categories are shared by unrelated doc pages (Help -> jokes.sh vs tips.sh,
# Utilities -> functions_config.sh vs functions_syshealth.sh vs undocumented nixlper.sh
# bindings) or use a doc-page name that doesn't match the category word (Admin ->
# feature-admin-notice.md, Target -> feature-target-staging.md). Those are listed here,
# keyed by the command/alias name exactly as _build_command_registry emits it.
#
# A command/keybind with NO entry here and whose category has no matching help_<slug> or
# feature-<slug>.md file at all (e.g. Version, or the CTRL+X+O nixlper.sh-editor binding,
# which is only ever mentioned in the rotating "tips" list) is silently skipped — this script
# only checks docs that are supposed to exist, it does not require every command to have one.
#***********************************************************************************************************************
declare -A HELP_FILE_OVERRIDE=(
  [nconf]="config"
  [health]="syshealth"
  [joke]="jokes"
  [tip]="tips"
  [ap]="files_folders"
  [CTRL_X_E]="files_folders"
  [CTRL_X_R]="files_folders"
  [cdf]="navigation"
  [rd]="recent_dirs"
)

declare -A DOC_PAGE_OVERRIDE=(
  [nconf]="configuration"
  [health]="system-health"
  [joke]="jokes"
  [tip]="tips"
  [bset]="admin-notice"
  [bclear]="admin-notice"
  [bshow]="admin-notice"
  [target_copy]="target-staging"
  [target_set]="target-staging"
  [target_mark]="target-staging"
  [target_list_marks]="target-staging"
  [target_unmark]="target-staging"
  [target_clear_marks]="target-staging"
  [target_pack]="target-staging"
  [target_clean]="target-staging"
  [ap]="files-folders"
  [CTRL_X_E]="files-folders"
  [CTRL_X_R]="files-folders"
  [cdf]="navigation"
)

#***********************************************************************************************************************
# Functions
#***********************************************************************************************************************
function _default_help_slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '&' | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//' | tr ' ' '_'
}

function _default_doc_slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '&' | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//' | tr ' ' '-'
}

# Keybinds are written inconsistently across docs ("CTRL+X+E" in the annotation,
# "[CTRL + X then E]" or "CTRL + X THEN E" in prose). Normalize both sides down to bare
# uppercase alphanumerics before comparing, so formatting differences don't count as drift.
function _normalize_keybind() {
  echo "$1" | tr '[:lower:]' '[:upper:]' | sed 's/\bTHEN\b//g' | tr -cd '[:alnum:]'
}

#***********************************************************************************************************************
# Entry point
#***********************************************************************************************************************
# shellcheck source=../src/main/bash/functions_command_palette.sh
source "${BASH_SRC_DIR}/functions_command_palette.sh"
export NIXLPER_INSTALL_DIR="${CURRENT_DIR}"

errors=0
files_checked=0
commands_checked=0

while IFS='|' read -r cmd_name description category keybind alias_name _rest; do
  [[ -z "$cmd_name" ]] && continue
  commands_checked=$((commands_checked + 1))

  help_slug="${HELP_FILE_OVERRIDE[$cmd_name]:-$(_default_help_slug "$category")}"
  doc_slug="${DOC_PAGE_OVERRIDE[$cmd_name]:-$(_default_doc_slug "$category")}"

  # Only check the command-name token when an @alias was explicitly declared. Bind-template
  # entries (CTRL+X+E style rm helpers) get a synthetic cmd_name derived from the keybind
  # itself ("CTRL_X_E") that is never real text to search for. A command with no @alias is
  # typically keybind-only by design (e.g. bind_last_macro, _add_or_remove_bookmark) — its
  # bare function name isn't something a user ever types, so it isn't a fact worth enforcing;
  # its keybind (checked separately below) is.
  tokens=()
  if [[ -n "$alias_name" && "$alias_name" != "bind" ]]; then
    tokens+=("$cmd_name")
  fi

  for target in "${HELP_DIR}/help_${help_slug}" "${DOCS_DIR}/feature-${doc_slug}.md" "${DOCS_FR_DIR}/feature-${doc_slug}.md"; do
    [[ -f "$target" ]] || continue
    files_checked=$((files_checked + 1))

    for token in "${tokens[@]}"; do
      if ! grep -qF -- "$token" "$target"; then
        echo "MISSING: '${token}' (command: ${cmd_name}, category: ${category}) not found in ${target#"${CURRENT_DIR}"/}"
        errors=$((errors + 1))
      fi
    done

    if [[ -n "$keybind" ]]; then
      normalized_keybind="$(_normalize_keybind "$keybind")"
      normalized_target="$(_normalize_keybind "$(cat "$target")")"
      if [[ "$normalized_target" != *"$normalized_keybind"* ]]; then
        echo "MISSING: '${keybind}' (command: ${cmd_name}, category: ${category}) not found in ${target#"${CURRENT_DIR}"/}"
        errors=$((errors + 1))
      fi
    fi
  done
done < <(_build_command_registry)

echo ""
if [[ ${errors} -eq 0 ]]; then
  echo "✅ doc-sync: ${commands_checked} commands, ${files_checked} doc/help files checked, nothing missing"
  exit 0
else
  echo "🔴 doc-sync: ${errors} missing reference(s) — see above"
  echo "   Add the command/keybind to the listed file(s), or if it genuinely has no doc/help"
  echo "   home, add a slug override in scripts/check-doc-sync.sh."
  exit 1
fi
