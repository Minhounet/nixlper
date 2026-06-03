#!/usr/bin/env bash
########################################################################################################################
# FILE: build-deb.sh
# DESCRIPTION: Build a nixlper DEB package for Ubuntu/Debian.
#              Requires: dpkg-deb (standard on any Debian-based system)
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
# Version — strip leading 'v' from git tag (e.g. v1.2.3 → 1.2.3).
# Fallback to short SHA for dev builds.
#-----------------------------------------------------------------------------------------------------------------------
_get_version() {
  local tag
  tag=$(git describe --tags --exact-match HEAD 2>/dev/null | sed 's/^v//' || true)
  if [[ -n "${tag}" ]]; then
    echo "${tag}"
  else
    # DEB version must start with a digit; prefix dev SHA with 0~
    echo "0~$(git log -n 1 --pretty=format:%h)"
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Locate the tar produced by build.sh
#-----------------------------------------------------------------------------------------------------------------------
_get_tar_path() {
  local -r version="$1"
  local -r versioned="${SCRIPT_DIR}/build/distributions/nixlper-${version}.tar"
  local -r unversioned="${SCRIPT_DIR}/build/distributions/nixlper.tar"
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
  _log_info "Build nixlper DEB"
  _log_separator

  if ! command -v dpkg-deb &>/dev/null; then
    _log_error "dpkg-deb not found — install the dpkg package"
    exit 1
  fi

  local -r version=$(_get_version)
  _log_info "Version: ${version}"

  # Build the bash tar first
  _log_info "Building nixlper tar..."
  bash "${SCRIPT_DIR}/build.sh"
  _log_ok "Tar built"

  local -r tar_path=$(_get_tar_path "${version}")
  _log_info "Using tar: ${tar_path}"

  # Set up clean staging tree
  local -r staging="${SCRIPT_DIR}/build/deb/nixlper_${version}_all"
  rm -rf "${staging}"
  mkdir -p "${staging}/DEBIAN"
  mkdir -p "${staging}/usr/share/nixlper/help"
  mkdir -p "${staging}/usr/share/doc/nixlper"
  mkdir -p "${staging}/etc/nixlper"
  mkdir -p "${staging}/etc/profile.d"

  # Scripts and help files
  tar -xf "${tar_path}" -C "${staging}/usr/share/nixlper"
  chmod 644 "${staging}/usr/share/nixlper/nixlper.sh"
  chmod 644 "${staging}/usr/share/nixlper/version"
  chmod 644 "${staging}/usr/share/nixlper/help/"*

  # System config — admin-editable, preserved on upgrade
  install -m 644 "${SCRIPT_DIR}/packaging/shared/nixlper.conf" \
    "${staging}/etc/nixlper/nixlper.conf"

  # profile.d loader — one line, activates nixlper for all users at login
  install -m 644 "${SCRIPT_DIR}/packaging/shared/nixlper-profile.d.sh" \
    "${staging}/etc/profile.d/nixlper.sh"

  # DEBIAN/control
  cat > "${staging}/DEBIAN/control" <<EOF
Package: nixlper
Version: ${version}
Architecture: all
Maintainer: Quang-Minh TRAN <qgmh.tran@gmail.com>
Depends: bash (>= 4.0)
Recommends: vim, tree
Description: Bash helper for keyboard-driven file and directory management
 Nixlper provides directory bookmarks, navigation, file operations, process
 management, macros, clipboard support, and a command palette for the shell.
 .
 Activated automatically for all users via /etc/profile.d/nixlper.sh.
 System defaults in /etc/nixlper/nixlper.conf (preserved on upgrade).
 Per-user overrides in ~/.config/nixlper/nixlper.conf.
EOF

  # DEBIAN/conffiles — only nixlper.conf is preserved on upgrade.
  # profile.d is intentionally NOT listed: it is always replaced on upgrade
  # and removed cleanly on dpkg -r.
  cat > "${staging}/DEBIAN/conffiles" <<EOF
/etc/nixlper/nixlper.conf
EOF

  # copyright (required by Debian policy)
  cat > "${staging}/usr/share/doc/nixlper/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: nixlper
Upstream-Contact: Quang-Minh TRAN <qgmh.tran@gmail.com>
Source: https://github.com/Minhounet/nixlper

Files: *
Copyright: 2023 Quang-Minh TRAN
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

  _log_ok "Staging tree ready"

  # Build the .deb
  local -r output_dir="${SCRIPT_DIR}/build/distributions"
  local -r deb_path="${output_dir}/nixlper_${version}_all.deb"
  dpkg-deb --build --root-owner-group "${staging}" "${deb_path}"

  _log_separator
  _log_ok "DEB built successfully"
  _log_info "Package: ${deb_path}"
  _log_separator
}

main "$@"
