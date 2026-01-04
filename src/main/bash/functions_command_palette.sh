#!/usr/bin/env bash
########################################################################################################################
# FILE: command_palette.sh
# DESCRIPTION: Command palette (Find Action) - Search and execute commands interactively
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _build_command_registry: Build a searchable registry of all available commands
# Dynamically parses @cmd-palette annotations from source files
# Output format: command_name | description | category | keybinding | alias
#-----------------------------------------------------------------------------------------------------------------------
function _build_command_registry() {
  local bash_dir="${NIXLPER_INSTALL_DIR}"

  # If we're in development (source tree), use src/main/bash
  if [[ -d "${NIXLPER_INSTALL_DIR}/src/main/bash" ]]; then
    bash_dir="${NIXLPER_INSTALL_DIR}/src/main/bash"
  fi

  # Find all bash files and parse annotations
  local files=$(find "$bash_dir" -name "*.sh" -o -name "nixlper.sh" 2>/dev/null)

  # Parse each file for @cmd-palette annotations
  for file in $files; do
    _parse_cmd_palette_annotations "$file"
  done
}

#-----------------------------------------------------------------------------------------------------------------------
# _parse_cmd_palette_annotations: Parse @cmd-palette annotations from a file
# Args: $1 = file path
#-----------------------------------------------------------------------------------------------------------------------
function _parse_cmd_palette_annotations() {
  local file="$1"
  local in_annotation=0
  local description=""
  local category=""
  local keybind=""
  local alias_name=""
  local cmd_name=""

  while IFS= read -r line; do
    # Check if we're starting a new annotation block
    if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@cmd-palette ]]; then
      in_annotation=1
      description=""
      category=""
      keybind=""
      alias_name=""
      cmd_name=""
      continue
    fi

    # Parse annotation fields
    if [[ $in_annotation -eq 1 ]]; then
      if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@description:[[:space:]]*(.*) ]]; then
        description="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@category:[[:space:]]*(.*) ]]; then
        category="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@keybind:[[:space:]]*(.*) ]]; then
        keybind="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@alias:[[:space:]]*(.*) ]]; then
        alias_name="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z0-9_]+) ]] || [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z0-9_]+)= ]]; then
        # Found the function or alias definition - extract command name
        cmd_name="${BASH_REMATCH[1]}"

        # Use alias name if available, otherwise use function name
        if [[ -n "$alias_name" ]]; then
          cmd_name="$alias_name"
        fi

        # Output the parsed command
        if [[ -n "$cmd_name" && -n "$description" ]]; then
          echo "${cmd_name}|${description}|${category}|${keybind}|${alias_name}"
        fi

        # Reset for next annotation
        in_annotation=0
      elif [[ "$line" =~ ^[[:space:]]*bind ]]; then
        # Handle bind statements (keybindings without functions)
        # Extract a command name from the description or keybind
        if [[ -n "$keybind" && -n "$description" ]]; then
          # Create a pseudo command name from the keybind
          cmd_name=$(echo "$keybind" | tr '+' '_' | tr -d ' ')
          echo "${cmd_name}|${description}|${category}|${keybind}|"
        fi
        in_annotation=0
      fi
    fi
  done < "$file"
}

#-----------------------------------------------------------------------------------------------------------------------
# _format_command_for_display: Format a command entry for fzf display
# Args: $1 = command line from registry
#-----------------------------------------------------------------------------------------------------------------------
function _format_command_for_display() {
  local line="$1"

  # Skip comments and empty lines
  [[ "$line" =~ ^#.*$ ]] && return
  [[ -z "$line" ]] && return

  local cmd_name=$(echo "$line" | cut -d'|' -f1)
  local description=$(echo "$line" | cut -d'|' -f2)
  local category=$(echo "$line" | cut -d'|' -f3)
  local keybinding=$(echo "$line" | cut -d'|' -f4)
  local cmd_type=$(echo "$line" | cut -d'|' -f5)

  # Build display string with proper spacing
  local display=""
  local keybind_part=""
  local category_part=""

  # Add keybinding if exists (aligned to 20 chars)
  if [[ -n "$keybinding" ]]; then
    keybind_part=$(printf "%-20s" "[$keybinding]")
  else
    keybind_part=$(printf "%-20s" "")
  fi

  # Add category tag
  if [[ -n "$category" ]]; then
    category_part=" {$category}"
  fi

  # Output the formatted line (35 chars for command name to handle longer names)
  printf "%s%-35s%s%s\n" "$keybind_part" "$cmd_name" "$description" "$category_part"
}

#-----------------------------------------------------------------------------------------------------------------------
# _get_command_details: Get detailed information about a command for preview
# Args: $1 = selected line from fzf
#
# NOTE: This function is currently UNUSED and may be redundant since the one-line display already shows
# description, category, and keybinding. Consider removing if preview window doesn't add value.
# TODO: Evaluate for removal after Phase 2 implementation - keep only if we add useful preview info
# (e.g., parameters, examples, related commands)
#-----------------------------------------------------------------------------------------------------------------------
function _get_command_details() {
  local selected="$1"

  # Extract command name from the formatted display string
  # Format is: [KEYBIND]  COMMAND_NAME  DESCRIPTION {CATEGORY}
  local cmd_name=$(echo "$selected" | awk '{print $2}')

  # Find the command in registry and show details
  local registry_line=$(_build_command_registry | grep "^${cmd_name}|")

  if [[ -n "$registry_line" ]]; then
    local description=$(echo "$registry_line" | cut -d'|' -f2)
    local category=$(echo "$registry_line" | cut -d'|' -f3)
    local keybinding=$(echo "$registry_line" | cut -d'|' -f4)
    local cmd_type=$(echo "$registry_line" | cut -d'|' -f5)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Command: $cmd_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Description: $description"
    echo "Category:    $category"
    [[ -n "$keybinding" ]] && echo "Keybinding:  $keybinding"
    echo "Type:        $cmd_type"
    echo ""

    # Add usage examples based on command type
    case "$cmd_type" in
      "alias"|"function")
        echo "Usage: $cmd_name [arguments]"
        ;;
      "keybind")
        echo "Usage: Press $keybinding"
        ;;
    esac
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# _execute_command: Execute a command selected from the command palette
# Args: $1 = selected formatted line from fzf
#-----------------------------------------------------------------------------------------------------------------------
function _execute_command() {
  local selected="$1"

  # Extract command name from the formatted display string
  # Format is: [KEYBIND]  COMMAND_NAME  DESCRIPTION {CATEGORY}
  # or:                    COMMAND_NAME  DESCRIPTION {CATEGORY} (no keybind)

  # Remove keybinding part if present and extract command name
  local cmd_name=$(echo "$selected" | sed 's/^\[.*\][[:space:]]*//' | awk '{print $1}')

  if [[ -z "$cmd_name" ]]; then
    _i_log_as_error "Could not extract command name from selection"
    return 1
  fi

  # Look up the command in the registry to get its details
  local registry_line=$(_build_command_registry | grep "^${cmd_name}|")

  if [[ -z "$registry_line" ]]; then
    _i_log_as_error "Command '${cmd_name}' not found in registry"
    return 1
  fi

  local keybinding=$(echo "$registry_line" | cut -d'|' -f4)

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Executing: $cmd_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Check if this is a keybinding-only command (pseudo commands like CTRL_X_E)
  if [[ "$cmd_name" =~ ^CTRL.*$ ]] && [[ -n "$keybinding" ]]; then
    echo "Note: This is a keybinding command: $keybinding"
    echo "Please use the keybinding directly in your terminal."
    echo ""
    return 0
  fi

  # Check if the command exists as a function or alias
  if type -t "$cmd_name" &>/dev/null; then
    # Execute the command
    eval "$cmd_name"
  else
    _i_log_as_error "Command '${cmd_name}' is not available (not a function, alias, or executable)"
    return 1
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# find_action: Display command palette popup with searchable command list
# Alias: fa
# Keybind: CTRL+X+A
# @cmd-palette
# @description: Search and select commands interactively
# @category: Command Palette
# @keybind: CTRL+X+A
# @alias: fa
#-----------------------------------------------------------------------------------------------------------------------
function find_action() {
  # Check if fzf is available
  if ! command -v fzf &> /dev/null; then
    _i_log_as_error "fzf is not installed. Command palette requires fzf."
    echo "Install fzf: https://github.com/junegunn/fzf#installation"
    return 1
  fi

  # Build and format the command registry
  local commands_list=""
  while read -r line; do
    _format_command_for_display "$line"
  done < <(_build_command_registry)

  # Display the command palette with fzf
  local selected
  selected=$(while read -r line; do _format_command_for_display "$line"; done < <(_build_command_registry) | \
    fzf \
      --ansi \
      --header="╔═══════════════════════════════════════════════════════════════════════════╗
║                    NIXLPER COMMAND PALETTE (Find Action)                  ║
║  Type to search commands by name, description, or category                ║
║  ESC: Cancel  |  ENTER: Execute selected command                         ║
╚═══════════════════════════════════════════════════════════════════════════╝" \
      --header-lines=0 \
      --prompt="Search commands > " \
      --height=80% \
      --border=rounded \
      --preview-window=hidden \
      --color="header:cyan,prompt:green,pointer:yellow")

  # Execute the selected command
  if [[ -n "$selected" ]]; then
    _execute_command "$selected"
  else
    echo "Command palette cancelled"
  fi
}

