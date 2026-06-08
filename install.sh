#!/usr/bin/env bash
########################################################################################################################
# FILE: install.sh
# DESCRIPTION: Download and install (or update) the latest version of Nixlper from GitHub releases
########################################################################################################################
set -o nounset
set -o errexit
set -o pipefail

readonly GITHUB_REPO="Minhounet/nixlper"
readonly DEFAULT_INSTALL_DIR="/opt/nixlper"

#***********************************************************************************************************************
# Logging
#***********************************************************************************************************************
_log_info() {
  echo "ℹ️  $1"
}

_log_ok() {
  echo "✅ $1"
}

_log_error() {
  echo "❌ $1" >&2
}

_log_separator() {
  echo "====================================================================================================="
}

#***********************************************************************************************************************
# Prerequisites check
#***********************************************************************************************************************
_check_prerequisites() {
  local missing=0

  for cmd in curl tar; do
    if ! command -v "${cmd}" &>/dev/null; then
      _log_error "${cmd} is required but not installed"
      missing=1
    fi
  done

  if [[ ${missing} -eq 1 ]]; then
    exit 1
  fi
}

#***********************************************************************************************************************
# Internet reachability — install/update is impossible (and must be disabled) when offline.
#***********************************************************************************************************************
_check_internet() {
  if ! curl -fsS --max-time 5 -o /dev/null "https://api.github.com" 2>/dev/null; then
    _log_error "Internet is not reachable — cannot fetch Nixlper. Install/update disabled."
    _log_info "Reconnect and try again, or set NIXLPER_UPDATE_CHANNEL=off to silence update checks."
    exit 1
  fi
}

#***********************************************************************************************************************
# GitHub release helpers
#***********************************************************************************************************************
_get_latest_release_tag() {
  local tag
  tag=$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/')

  if [[ -z "${tag}" ]]; then
    _log_error "Could not determine the latest release tag"
    exit 1
  fi
  echo "${tag}"
}

_download_release() {
  local -r tag="$1"
  local -r dest_dir="$2"
  local -r archive_name="nixlper-${tag}.tar"
  local -r download_url="https://github.com/${GITHUB_REPO}/releases/download/${tag}/${archive_name}"

  _log_info "Downloading ${archive_name} ..."
  if ! curl -fSL --progress-bar -o "${dest_dir}/${archive_name}" "${download_url}"; then
    _log_error "Failed to download ${download_url}"
    exit 1
  fi
  _log_ok "Downloaded ${archive_name}"
  echo "${dest_dir}/${archive_name}"
}

#***********************************************************************************************************************
# Detect existing installation
#***********************************************************************************************************************
_is_nixlper_installed() {
  # Check 1: environment variable set by a previous installation
  if [[ -n "${NIXLPER_INSTALL_DIR:-}" ]] && [[ -f "${NIXLPER_INSTALL_DIR}/nixlper.sh" ]]; then
    return 0
  fi

  # Check 2: .bashrc contains the nixlper block (per-user install)
  if grep -q "nixlper start" ~/.bashrc 2>/dev/null; then
    return 0
  fi

  # Check 3: system-wide install markers
  if [[ -f /etc/profile.d/nixlper.sh ]] || [[ -f /etc/nixlper/nixlper.conf ]]; then
    return 0
  fi

  return 1
}

_get_current_install_dir() {
  # Try from environment first
  if [[ -n "${NIXLPER_INSTALL_DIR:-}" ]] && [[ -d "${NIXLPER_INSTALL_DIR}" ]]; then
    echo "${NIXLPER_INSTALL_DIR}"
    return
  fi

  # Fall back to parsing .bashrc (per-user install)
  local dir
  dir=$(grep 'export NIXLPER_INSTALL_DIR=' ~/.bashrc 2>/dev/null \
        | tail -1 \
        | sed 's/export NIXLPER_INSTALL_DIR=//')

  if [[ -n "${dir}" ]] && [[ -d "${dir}" ]]; then
    echo "${dir}"
    return
  fi

  # Fall back to system conf
  if [[ -f /etc/nixlper/nixlper.conf ]]; then
    dir=$(bash -c 'source /etc/nixlper/nixlper.conf 2>/dev/null && echo "${NIXLPER_INSTALL_DIR:-}"')
    if [[ -n "${dir}" ]] && [[ -d "${dir}" ]]; then
      echo "${dir}"
      return
    fi
  fi

  echo ""
}

#***********************************************************************************************************************
# Install / Update logic
#***********************************************************************************************************************
_first_install() {
  local -r install_dir="$1"
  local -r archive_path="$2"
  local -r system_mode="${3:-false}"

  if [[ "${system_mode}" == "true" ]]; then
    _log_info "Performing system-wide install into ${install_dir}"
  else
    _log_info "Performing first install into ${install_dir}"
  fi

  mkdir -p "${install_dir}"
  tar -xf "${archive_path}" -C "${install_dir}"
  rm -f "${archive_path}"

  chmod +x "${install_dir}/nixlper.sh"

  cd "${install_dir}"
  if [[ "${system_mode}" == "true" ]]; then
    ./nixlper.sh install-system
  else
    ./nixlper.sh install
  fi

  _log_ok "Nixlper installed successfully in ${install_dir}"
  echo ""
  if [[ "${system_mode}" == "true" ]]; then
    _log_info "Nixlper will be activated for all users at next login."
  else
    _log_info "Please run one of the following to activate nixlper:"
    echo "    source ~/.bashrc"
    echo "    (or log out and log back in)"
  fi
}

_update_install() {
  local -r install_dir="$1"
  local -r archive_path="$2"
  local -r system_mode="${3:-false}"

  _log_info "Updating existing installation in ${install_dir}"

  # Back up custom scripts before overwriting
  local custom_backup=""
  if [[ -d "${install_dir}/custom" ]]; then
    custom_backup=$(mktemp -d)
    cp -a "${install_dir}/custom" "${custom_backup}/"
  fi

  # Extract new version over existing files
  tar -xf "${archive_path}" -C "${install_dir}"
  rm -f "${archive_path}"

  # Restore custom scripts
  if [[ -n "${custom_backup}" ]] && [[ -d "${custom_backup}/custom" ]]; then
    cp -a "${custom_backup}/custom/"* "${install_dir}/custom/" 2>/dev/null || true
    rm -rf "${custom_backup}"
  fi

  chmod +x "${install_dir}/nixlper.sh"

  cd "${install_dir}"
  if [[ "${system_mode}" == "true" ]]; then
    ./nixlper.sh update-system
  else
    ./nixlper.sh update
  fi

  _log_ok "Nixlper updated successfully"
  echo ""
  if [[ "${system_mode}" == "true" ]]; then
    _log_info "All users will get the new version at next login."
  else
    _log_info "Please run one of the following to activate the new version:"
    echo "    source ~/.bashrc"
    echo "    (or log out and log back in)"
  fi
}

#***********************************************************************************************************************
# Main
#***********************************************************************************************************************
main() {
  local system_mode=false
  local assume_yes=false
  local channel="stable"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --system) system_mode=true ;;
      --yes|-y) assume_yes=true ;;
      --channel)
        shift
        channel="${1:-stable}"
        ;;
      --channel=*) channel="${1#--channel=}" ;;
      *) _log_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
  done

  if [[ "${channel}" != "stable" && "${channel}" != "edge" ]]; then
    _log_error "Invalid --channel '${channel}' (use stable or edge)"
    exit 1
  fi

  _log_separator
  if [[ "${system_mode}" == "true" ]]; then
    echo "  Nixlper Installer (system-wide, ${channel} channel)"
  else
    echo "  Nixlper Installer (${channel} channel)"
  fi
  _log_separator
  echo ""

  if [[ "${system_mode}" == "true" ]] && [[ ${EUID} -ne 0 ]]; then
    _log_error "System-wide install requires root. Run: sudo $0 --system"
    exit 1
  fi

  _check_prerequisites
  _check_internet

  # Determine what to install for the selected channel.
  local tag
  if [[ "${channel}" == "edge" ]]; then
    # The edge channel tracks a single rolling pre-release, overwritten by CI on every push.
    tag="edge"
    _log_info "Edge channel — installing the latest commit build (${tag})"
  else
    _log_info "Fetching latest release information from GitHub ..."
    tag=$(_get_latest_release_tag)
    _log_ok "Latest release: ${tag}"
  fi
  echo ""

  if _is_nixlper_installed; then
    # ----- UPDATE PATH -----
    local install_dir
    install_dir=$(_get_current_install_dir)

    if [[ -z "${install_dir}" ]]; then
      install_dir="${DEFAULT_INSTALL_DIR}"
      _log_info "Could not determine current install directory, defaulting to ${install_dir}"
    fi

    _log_info "Nixlper is already installed in ${install_dir}"
    echo ""
    local answer="Y"
    if [[ "${assume_yes}" != "true" ]]; then
      read -r -p "Do you want to update to ${tag}? [Y/n] " answer
      answer=${answer:-Y}
    fi
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
      local archive_path
      archive_path=$(_download_release "${tag}" "${install_dir}")
      NIXLPER_INSTALL_CHANNEL="${channel}" _update_install "${install_dir}" "${archive_path}" "${system_mode}"
    else
      _log_info "Update cancelled"
    fi
  else
    # ----- FIRST INSTALL PATH -----
    local install_dir="${DEFAULT_INSTALL_DIR}"

    if [[ "${assume_yes}" != "true" ]]; then
      echo "Nixlper is not installed on this system."
      read -r -p "Install directory [${DEFAULT_INSTALL_DIR}]: " custom_dir
      if [[ -n "${custom_dir}" ]]; then
        install_dir="${custom_dir}"
      fi
    fi

    local answer="Y"
    if [[ "${assume_yes}" != "true" ]]; then
      read -r -p "Install Nixlper ${tag} into ${install_dir}? [Y/n] " answer
      answer=${answer:-Y}
    fi
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
      local archive_path
      archive_path=$(_download_release "${tag}" "/tmp")
      NIXLPER_INSTALL_CHANNEL="${channel}" _first_install "${install_dir}" "/tmp/$(basename "${archive_path}")" "${system_mode}"
    else
      _log_info "Installation cancelled"
    fi
  fi

  echo ""
  _log_separator
}

main "$@"
