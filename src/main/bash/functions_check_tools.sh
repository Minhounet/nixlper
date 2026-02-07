#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_check_tools.sh
# DESCRIPTION: Detect missing tools at startup and warn the user
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# _i_check_tools: Check for required and optional tool dependencies
# Called during nixlper initialization to warn about missing tools
#-----------------------------------------------------------------------------------------------------------------------
function _i_check_tools() {
  local missing_required=()
  local missing_optional=()

  # Required tools - core Unix tools used across multiple modules
  local -a required_tools=("sed" "awk" "grep" "find")
  for tool in "${required_tools[@]}"; do
    if ! command -v "${tool}" &>/dev/null; then
      missing_required+=("${tool}")
    fi
  done

  # Optional tools - feature-specific, with descriptions of what is affected
  # Format: "tool|affected feature description"
  local -a optional_tool_entries=(
    "fzf|command palette (fa) and help search (CTRL+X+H)"
    "tree|tree navigation mode (navigate)"
    "netstat|kill by port (ik --port)"
    "less|help paging"
  )

  for entry in "${optional_tool_entries[@]}"; do
    local tool="${entry%%|*}"
    local feature="${entry#*|}"
    if ! command -v "${tool}" &>/dev/null; then
      missing_optional+=("${tool} -> needed by: ${feature}")
    fi
  done

  # Clipboard: at least one of xclip, xsel, pbcopy is needed
  if ! command -v xclip &>/dev/null && ! command -v xsel &>/dev/null && ! command -v pbcopy &>/dev/null; then
    missing_optional+=("xclip/xsel/pbcopy -> needed by: clipboard operations (cpcb, cpdcb)")
  fi

  # Report results
  if [[ ${#missing_required[@]} -gt 0 ]]; then
    _i_log_as_error "Missing required tools: ${missing_required[*]}"
    _i_log_as_error "Some nixlper features may not work correctly."
  fi

  if [[ ${#missing_optional[@]} -gt 0 ]]; then
    _i_log_as_info "Missing optional tools:"
    for entry in "${missing_optional[@]}"; do
      echo "  - ${entry}"
    done
  fi
}
