#!/usr/bin/env bash
########################################################################################################################
# FILE: command_palette.sh
# DESCRIPTION: Command palette (Find Action) - Search and execute commands interactively
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _register_keybindings: Register all keybind commands
#-----------------------------------------------------------------------------------------------------------------------
function _register_keybindings() {
  echo "CTRL_X_D|Display existing bookmarks with aliases|Bookmarks|CTRL+X+D|bind|_display_existing_bookmarks|0"
  echo "CTRL_X_B|Add or remove bookmark for current folder|Bookmarks|CTRL+X+B|bind|_add_or_remove_bookmark\15|0"
  echo "CTRL_X_H|Interactive help search|Help|CTRL+X+H|bind|_help\15|0"
  echo "CTRL_X_V|Display nixlper logo and version|Version|CTRL+X+V|bind|_display_logo_and_version|0"
  echo "CTRL_X_E|Display safe rm command to delete current folder|Utilities|CTRL+X+E|bind|rm -rf \$(pwd)/\33\5 && cd ..|1"
  echo "CTRL_X_R|Display safe rm command to delete folder contents|Utilities|CTRL+X+R|bind|rm -rf \$(pwd)/\33\5*|1"
  echo "CTRL_X_U|Go up one directory|Navigation|CTRL+X+U|bind|cd ..\15|0"
  echo "CTRL_X_N|Navigate folders interactively (tree/flat mode)|Navigation|CTRL+X+N|bind|navigate|0"
  echo "CTRL_X_O|Open nixlper.sh in editor|Utilities|CTRL+X+O|bind|\$NIXLPER_EDITOR \${NIXLPER_INSTALL_DIR}/nixlper.sh|0"
  echo "CTRL_X_A|Search and select commands interactively|Command Palette|CTRL+X+A|bind|find_action|0"
  echo "CTRL_P|Start recording bash commands|Macros|CTRL+P|bind|start_recording|0"
  echo "CTRL_P_CTRL_P|Stop and save macro recording|Macros|CTRL+P+CTRL+P|bind|finalize_recording|0"
  echo "CTRL_P_CTRL_L|Replay last recorded macro|Macros|CTRL+P+CTRL+L|bind|bind_last_macro|0"
}

#-----------------------------------------------------------------------------------------------------------------------
# _register_aliases: Register all alias commands
#-----------------------------------------------------------------------------------------------------------------------
function _register_aliases() {
  echo "fa|Search and select commands interactively|Command Palette|CTRL+X+A|fa|0"
  echo "ik|Interactive kill by pattern or port|Processes||ik|0"
  echo "sr|Start recording bash commands|Macros|CTRL+P|sr|0"
  echo "fr|Stop and save macro recording|Macros|CTRL+P+CTRL+P|fr|0"
  echo "c|Mark current folder (use 'gc' to return)|Files & Folders||c|0"
  echo "cf|Mark file as current (use 'gcf' to open)|Files & Folders||cf|0"
  echo "sn|Snapshot file to snapshots area|Files & Folders||sn|0"
  echo "re|Restore file from snapshots|Files & Folders||re|0"
  echo "cdf|Change to the folder containing a file|Files & Folders||cdf|0"
  echo "cpcb|Copy full file path to clipboard|Files & Folders||cpcb|0"
  echo "cpdcb|Copy directory path to clipboard|Files & Folders||cpdcb|0"
  echo "sucd|Switch user and maintain current directory|Users||sucd|0"
  echo "ap|Prepend current path to PATH in .bashrc|Utilities||ap|0"
  echo "fan|Find and navigate using pattern matching|Navigation||fan|0"
}

#-----------------------------------------------------------------------------------------------------------------------
# _register_functions: Register all function commands (that aren't already registered as bindings)
#-----------------------------------------------------------------------------------------------------------------------
function _register_functions() {
  echo "_display_existing_bookmarks|Display existing bookmarks with aliases|Bookmarks|CTRL+X+D||0"
  echo "_add_or_remove_bookmark|Add or remove bookmark for current folder|Bookmarks|CTRL+X+B||0"
  echo "_help|Interactive help search|Help|CTRL+X+H||0"
  echo "_display_logo_and_version|Display nixlper logo and version|Version|CTRL+X+V||0"
  echo "navigate|Navigate folders interactively (tree/flat mode)|Navigation|CTRL+X+N||0"
  echo "bind_last_macro|Replay last recorded macro|Macros|CTRL+P+CTRL+L||0"
  echo "toggle_navigation_mode|Toggle size/permissions display in navigate|Navigation|||0"
}

#-----------------------------------------------------------------------------------------------------------------------
# _build_command_registry: Build a searchable registry of all available commands
# Uses programmatic registration instead of parsing to survive build process
# Output format: command_name | description | category | keybinding | alias | is_template
#-----------------------------------------------------------------------------------------------------------------------
function _build_command_registry() {
  _register_keybindings
  _register_aliases
  _register_functions
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
  local is_template=0

  while IFS= read -r line; do
    # Check if we're starting a new annotation block
    if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@cmd-palette ]]; then
      in_annotation=1
      description=""
      category=""
      keybind=""
      alias_name=""
      cmd_name=""
      is_template=0
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
      elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@template ]]; then
        is_template=1
      elif [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z0-9_]+) ]] || [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z0-9_]+)= ]]; then
        # Found the function or alias definition - extract command name
        cmd_name="${BASH_REMATCH[1]}"

        # Use alias name if available, otherwise use function name
        if [[ -n "$alias_name" ]]; then
          cmd_name="$alias_name"
        fi

        # Output the parsed command
        if [[ -n "$cmd_name" && -n "$description" ]]; then
          echo "${cmd_name}|${description}|${category}|${keybind}|${alias_name}|${is_template}"
        fi

        # Reset for next annotation
        in_annotation=0
      elif [[ "$line" =~ ^[[:space:]]*bind ]]; then
        # Handle bind statements - extract the command being bound
        if [[ -n "$keybind" && -n "$description" ]]; then
          # Create a descriptive command name from the keybind
          cmd_name=$(echo "$keybind" | tr '+' '_' | tr -d ' ')

          # Extract the command from the bind statement
          # Pattern 1: bind '"\C-x\C-u": "COMMAND_HERE"' - quoted command
          # Pattern 2: bind -x '"\C-x\C-u": COMMAND_HERE' - unquoted command
          local bind_command=""

          if [[ "$line" =~ :[[:space:]]*\"([^\"]+)\" ]]; then
            # Quoted command (regular bind)
            bind_command="${BASH_REMATCH[1]}"
          elif [[ "$line" =~ :[[:space:]]*(.+)\'[[:space:]]*$ ]]; then
            # Unquoted command (bind -x) - capture everything after colon until closing quote
            bind_command="${BASH_REMATCH[1]}"
          fi

          # Store: cmd_name|description|category|keybind|type|bind_command|is_template
          echo "${cmd_name}|${description}|${category}|${keybind}|bind|${bind_command}|${is_template}"
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
  local type_indicator=""

  # Add keybinding if exists (aligned to 20 chars)
  if [[ -n "$keybinding" ]]; then
    keybind_part=$(printf "%-20s" "[$keybinding]")
  else
    keybind_part=$(printf "%-20s" "")
  fi

  # Add type indicator for aliases
  if [[ -n "$cmd_type" && "$cmd_type" == "$cmd_name" && "$cmd_type" != "bind" ]]; then
    type_indicator="[alias] "
  fi

  # Add category tag
  if [[ -n "$category" ]]; then
    category_part=" {$category}"
  fi

  # Output the formatted line (35 chars for command name to handle longer names)
  printf "%s%-35s%s%s%s\n" "$keybind_part" "$cmd_name" "${type_indicator}${description}" "$category_part"
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
# _clean_bind_command: Clean escape sequences from a bind command string
# Args: $1 = raw bind command with escape sequences
# Returns: cleaned command ready for execution
#-----------------------------------------------------------------------------------------------------------------------
function _clean_bind_command() {
  local raw_command="$1"

  # Remove common escape sequences:
  # \15 = carriage return (octal)
  # \33\5 = ESC + CTRL+E (cursor movement)
  # Other escape sequences can be added as needed

  local cleaned_command="$raw_command"

  # Remove \15 (carriage return - used to execute the command)
  cleaned_command="${cleaned_command//\\15/}"

  # Remove \33\5 (ESC + CTRL+E - cursor movement to end of line)
  cleaned_command="${cleaned_command//\\33\\5/}"

  # Remove trailing/leading whitespace
  cleaned_command=$(echo "$cleaned_command" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  echo "$cleaned_command"
}

#-----------------------------------------------------------------------------------------------------------------------
# _execute_command: Execute a command selected from the command palette
# Args: $1 = selected formatted line from fzf
#-----------------------------------------------------------------------------------------------------------------------
function _execute_command() {
  # Enable alias expansion for eval
  shopt -s expand_aliases

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
  local cmd_type=$(echo "$registry_line" | cut -d'|' -f5)
  local bind_command=$(echo "$registry_line" | cut -d'|' -f6)
  local is_template=$(echo "$registry_line" | cut -d'|' -f7)

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Handle bind commands by extracting and executing the underlying command
  if [[ "$cmd_type" == "bind" ]]; then
    if [[ -z "$bind_command" ]]; then
      echo "Keybinding: $keybinding"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Could not extract command from bind statement."
      echo "Please use the keybinding directly: $keybinding"
      echo ""
      return 0
    fi

    # Clean the bind command by removing escape sequences
    local cleaned_command=$(_clean_bind_command "$bind_command")

    # Check if this is a template command (for display only, not execution)
    if [[ "$is_template" == "1" ]]; then
      echo "Template command: $cleaned_command"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "This is a template command for interactive editing."
      echo "Please use the keybinding directly: $keybinding"
      echo ""
      echo "The command template is:"
      echo "  $cleaned_command"
      echo ""
      return 0
    fi

    echo "Executing: $cleaned_command"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Execute the cleaned command
    eval "$cleaned_command"
    return $?
  fi

  echo "Executing: $cmd_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

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

