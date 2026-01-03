#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_clipboard.sh
# DESCRIPTION: Clipboard operations for copying file paths
########################################################################################################################

########################################################################################################################
# FUNCTION: _i_get_clipboard_tool
# DESCRIPTION: Detect and return the available clipboard tool
# RETURN: Echoes the clipboard command to use (xclip, xsel, pbcopy, or empty)
########################################################################################################################
function _i_get_clipboard_tool() {
  if command -v xclip &> /dev/null; then
    echo "xclip -selection clipboard"
  elif command -v xsel &> /dev/null; then
    echo "xsel --clipboard --input"
  elif command -v pbcopy &> /dev/null; then
    echo "pbcopy"
  else
    echo ""
  fi
}

########################################################################################################################
# FUNCTION: _copy_fullpath_to_clipboard
# DESCRIPTION: Copy the full path of a file or directory to the clipboard
# PARAMETERS:
#   $1 - File or directory name (optional, defaults to current directory)
# USAGE: cpcb [filename]
# EXAMPLE:
#   cpcb                    # Copies current directory full path
#   cpcb myfile.txt         # Copies full path of myfile.txt
#   cpcb ../some/path       # Copies full path of relative path
########################################################################################################################
function _copy_fullpath_to_clipboard() {
  local target="${1:-.}"
  local fullpath
  local clipboard_tool

  # Check if clipboard tool is available
  clipboard_tool=$(_i_get_clipboard_tool)
  if [[ -z "$clipboard_tool" ]]; then
    _i_log_as_error "No clipboard tool found. Please install xclip, xsel, or pbcopy."
    return 1
  fi

  # Check if the target exists
  if [[ ! -e "$target" ]]; then
    _i_log_as_error "File or directory '$target' does not exist."
    return 1
  fi

  # Get the absolute path
  fullpath=$(realpath "$target" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    # Fallback if realpath is not available
    fullpath=$(cd "$(dirname "$target")" && pwd)/$(basename "$target")
  fi

  # Copy to clipboard
  echo -n "$fullpath" | eval "$clipboard_tool"
  if [[ $? -eq 0 ]]; then
    _i_log_as_info "Copied to clipboard: $fullpath"
    _i_log_ok
  else
    _i_log_as_error "Failed to copy to clipboard."
    return 1
  fi
}
