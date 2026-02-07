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

  # Check 2: .bashrc contains the nixlper block
  if grep -q "nixlper start" ~/.bashrc 2>/dev/null; then
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

  # Fall back to parsing .bashrc
  local dir
  dir=$(grep 'export NIXLPER_INSTALL_DIR=' ~/.bashrc 2>/dev/null \
        | tail -1 \
        | sed 's/export NIXLPER_INSTALL_DIR=//')

  if [[ -n "${dir}" ]] && [[ -d "${dir}" ]]; then
    echo "${dir}"
    return
  fi

  echo ""
}

#***********************************************************************************************************************
# Install / Update logic
#***********************************************************************************************************************
_first_install() {
  local -r install_dir="$1"
  local -r archive_path="$2"

  _log_info "Performing first install into ${install_dir}"

  mkdir -p "${install_dir}"
  tar -xf "${archive_path}" -C "${install_dir}"
  rm -f "${archive_path}"

  chmod +x "${install_dir}/nixlper.sh"

  cd "${install_dir}"
  ./nixlper.sh install

  _log_ok "Nixlper installed successfully in ${install_dir}"
  echo ""
  _log_info "Please run one of the following to activate nixlper:"
  echo "    source ~/.bashrc"
  echo "    (or log out and log back in)"
}

_update_install() {
  local -r install_dir="$1"
  local -r archive_path="$2"

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
  ./nixlper.sh update

  _log_ok "Nixlper updated successfully"
  echo ""
  _log_info "Please run one of the following to activate the new version:"
  echo "    source ~/.bashrc"
  echo "    (or log out and log back in)"
}

#***********************************************************************************************************************
# Main
#***********************************************************************************************************************
main() {
  _log_separator
  echo "  Nixlper Installer"
  _log_separator
  echo ""

  _check_prerequisites

  # Determine the latest release
  _log_info "Fetching latest release information from GitHub ..."
  local -r tag=$(_get_latest_release_tag)
  _log_ok "Latest release: ${tag}"
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
    read -r -p "Do you want to update to version ${tag}? [Y/n] " answer
    answer=${answer:-Y}
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
      local archive_path
      archive_path=$(_download_release "${tag}" "${install_dir}")
      _update_install "${install_dir}" "${archive_path}"
    else
      _log_info "Update cancelled"
    fi
  else
    # ----- FIRST INSTALL PATH -----
    local install_dir="${DEFAULT_INSTALL_DIR}"

    echo "Nixlper is not installed on this system."
    read -r -p "Install directory [${DEFAULT_INSTALL_DIR}]: " custom_dir
    if [[ -n "${custom_dir}" ]]; then
      install_dir="${custom_dir}"
    fi

    read -r -p "Install Nixlper ${tag} into ${install_dir}? [Y/n] " answer
    answer=${answer:-Y}
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
      local archive_path
      archive_path=$(_download_release "${tag}" "/tmp")
      _first_install "${install_dir}" "/tmp/$(basename "${archive_path}")"
    else
      _log_info "Installation cancelled"
    fi
  fi

  echo ""
  _log_separator
}

main "$@"
