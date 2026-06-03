#!/usr/bin/env bash
########################################################################################################################
# FILE: build-rpm.sh
# DESCRIPTION: Build a nixlper RPM package.
#              Requires: rpmbuild (rpm-build package on RHEL/Fedora/Rocky)
########################################################################################################################
set -o nounset
set -o errexit
set -o pipefail

readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

_log_separator() { echo "====================================================================================="; }
_log_info()  { echo "ℹ️  $1"; }
_log_ok()    { echo "✅ $1"; }
_log_error() { echo "❌ $1" >&2; }

#-----------------------------------------------------------------------------------------------------------------------
# Version — strip leading 'v' from git tag so RPM Version: is plain numeric (e.g. 1.2.3 not v1.2.3)
#-----------------------------------------------------------------------------------------------------------------------
_get_version() {
  local tag
  tag=$(git describe --tags --exact-match HEAD 2>/dev/null | sed 's/^v//;s/-/_/g' || true)
  if [[ -n "${tag}" ]]; then
    echo "${tag}"
  else
    # Fallback to short SHA for dev builds
    git log -n 1 --pretty=format:%h
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Locate the tar produced by build.sh
#-----------------------------------------------------------------------------------------------------------------------
_get_tar_path() {
  local -r version="$1"
  local versioned="${SCRIPT_DIR}/build/distributions/nixlper-${version}.tar"
  local unversioned="${SCRIPT_DIR}/build/distributions/nixlper.tar"
  if [[ -f "${versioned}" ]]; then
    echo "${versioned}"
  elif [[ -f "${unversioned}" ]]; then
    echo "${unversioned}"
  else
    _log_error "No tar found in build/distributions/ — run build.sh first"
    return 1
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Main
#-----------------------------------------------------------------------------------------------------------------------
main() {
  _log_separator
  _log_info "Build nixlper RPM"
  _log_separator

  # Check rpmbuild is available
  if ! command -v rpmbuild &>/dev/null; then
    _log_error "rpmbuild not found — install rpm-build package (dnf install rpm-build)"
    exit 1
  fi

  # Resolve version
  local -r version=$(_get_version)
  local -r changelog_date=$(date "+%a %b %d %Y")
  _log_info "Version: ${version}"

  # Build the bash tar first
  _log_info "Building nixlper tar..."
  bash "${SCRIPT_DIR}/build.sh"
  _log_ok "Tar built"

  # Locate tar
  local -r tar_path=$(_get_tar_path "${version}")
  _log_info "Using tar: ${tar_path}"

  # Set up rpmbuild tree
  local -r rpmbuild_dir="${HOME}/rpmbuild"
  mkdir -p "${rpmbuild_dir}"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

  # Copy all sources
  cp "${tar_path}" "${rpmbuild_dir}/SOURCES/nixlper-${version}.tar"
  cp "${SCRIPT_DIR}/packaging/shared/nixlper.conf"          "${rpmbuild_dir}/SOURCES/nixlper.conf"
  cp "${SCRIPT_DIR}/packaging/shared/nixlper-profile.d.sh"  "${rpmbuild_dir}/SOURCES/nixlper-profile.d.sh"
  cp "${SCRIPT_DIR}/LICENSE"                                 "${rpmbuild_dir}/SOURCES/LICENSE"
  cp "${SCRIPT_DIR}/packaging/rpm/nixlper.spec"              "${rpmbuild_dir}/SPECS/nixlper.spec"
  _log_ok "Sources staged in ${rpmbuild_dir}/SOURCES/"

  # Build binary RPM
  _log_info "Running rpmbuild..."
  rpmbuild -bb \
    --define "nixlper_version ${version}" \
    --define "nixlper_changelog_date ${changelog_date}" \
    "${rpmbuild_dir}/SPECS/nixlper.spec"

  _log_separator
  _log_ok "RPM built successfully"
  _log_info "Package location:"
  find "${rpmbuild_dir}/RPMS" -name "nixlper-*.rpm" | sort
  _log_separator
}

main "$@"
