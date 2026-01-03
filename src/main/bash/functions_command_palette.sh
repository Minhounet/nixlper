#!/usr/bin/env bash
########################################################################################################################
# FILE: command_palette.sh
# DESCRIPTION: Command palette (Find Action) - Search and execute commands interactively
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _build_command_registry: Build a searchable registry of all available commands
# Output format: command_name | description | category | keybinding | type
#-----------------------------------------------------------------------------------------------------------------------
function _build_command_registry() {
  cat <<'EOF'
# BOOKMARKS
_display_existing_bookmarks|Display existing bookmarks with aliases|Bookmarks|CTRL+X+D|keybind
_add_or_remove_bookmark|Add or remove bookmark for current folder|Bookmarks|CTRL+X+B|keybind
projects_alias|Jump to bookmarked path (dynamic aliases)|Bookmarks||alias

# FILES & FOLDERS
c|Mark current folder (use 'gc' to return)|Files & Folders||alias
cf|Mark file as current (use 'gcf' to open)|Files & Folders||alias
cdf|Change to the folder containing a file|Files & Folders||alias
cpcb|Copy full file path to clipboard|Files & Folders||alias
cpdcb|Copy directory path to clipboard|Files & Folders||alias
sn|Snapshot file to snapshots area|Files & Folders||alias
re|Restore file from snapshots|Files & Folders||alias
fan|Find and navigate using pattern matching|Files & Folders||alias
_mark_folder_as_current|Mark current folder (internal function)|Files & Folders||function
_mark_file_as_current|Mark file as current (internal function)|Files & Folders||function
_change_directory_from_filepath|Change to directory from file path|Files & Folders||function
_copy_fullpath_to_clipboard|Copy full path to clipboard|Files & Folders||function
_copy_directory_to_clipboard|Copy directory to clipboard|Files & Folders||function
_snapshot_file|Snapshot file to snapshots area|Files & Folders||function
_restore_file|Restore file from snapshots|Files & Folders||function
_find_and_navigate|Find and navigate by pattern|Files & Folders||function

# NAVIGATION
navigate|Navigate folders interactively (tree/flat mode)|Navigation|CTRL+X+N|keybind
toggle_navigation_mode|Toggle size/permissions display in navigate|Navigation||function
n1_n2_etc|Navigate to folder N (dynamic aliases)|Navigation|CTRL+X+NUMBER|keybind
v1_v2_etc|Open file N in editor (dynamic aliases)|Navigation||alias
cd_..|Go up one directory|Navigation|CTRL+X+U|keybind

# PROCESSES
ik|Interactive kill by pattern or port|Processes||alias
_interactive_kill|Interactive kill process (internal)|Processes||function

# MACROS
start_recording|Start recording bash commands|Macros|CTRL+P|keybind
finalize_recording|Stop and save macro recording|Macros|CTRL+P+CTRL+P|keybind
bind_last_macro|Replay last recorded macro|Macros|CTRL+P+CTRL+L|keybind
sr|Start recording (alias)|Macros||alias
fr|Finalize recording (alias)|Macros||alias

# USERS
sucd|Switch user and maintain current directory|Users||alias
_su_to_current_directory|Switch user to current dir (internal)|Users||function

# HELP & VERSION
_help|Interactive help search|Help|CTRL+X+H|keybind
_display_logo_and_version|Display nixlper logo and version|Version|CTRL+X+V|keybind

# UTILITIES
ap|Prepend current path to PATH in .bashrc|Utilities||alias
delete_current_folder|Display safe rm command for current folder|Utilities|CTRL+X+E|keybind
delete_folder_contents|Display safe rm command for folder contents|Utilities|CTRL+X+R|keybind
open_nixlper|Open nixlper.sh in editor|Utilities|CTRL+X+O|keybind
EOF
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

