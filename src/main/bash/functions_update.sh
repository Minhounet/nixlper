#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_update.sh
# DESCRIPTION: update detection across release channels (stable / edge) with an offline guard.
#
# Channels are selected with NIXLPER_UPDATE_CHANNEL:
#   stable (default) — track tagged GitHub releases; suggest an update when a newer tag exists.
#   edge             — track the latest commit on the default branch (a rolling "edge" pre-release
#                      is overwritten by CI on every push); suggest an update when HEAD moved.
#   off              — never touch the network, never check.
#
# All network access is gated by _i_is_online (a fast, time-boxed reachability probe), so a
# disconnected machine never hangs or errors at login. Automatic startup checks are throttled
# to NIXLPER_UPDATE_CHECK_INTERVAL seconds via a per-user cache file; the on-demand command
# (_check_update / alias nu / CTRL+X+W) bypasses the throttle and always reports a result.
########################################################################################################################

readonly NIXLPER_GITHUB_REPO="Minhounet/nixlper"

#-----------------------------------------------------------------------------------------------------------------------
# Internal helpers
#-----------------------------------------------------------------------------------------------------------------------
# Per-user, always-writable cache file holding the epoch of the last successful check.
function _i_update_cache_file() {
  echo "${NIXLPER_UPDATE_CACHE_FILE:-${NIXLPER_INSTALL_DIR}/.nixlper_update_check}"
}

# Return 0 if GitHub is reachable within NIXLPER_UPDATE_TIMEOUT seconds, 1 otherwise.
# Probes github.com (not api.github.com — that returns 403 in some environments, which
# curl -f treats as a failure even though the network is up).
function _i_is_online() {
  command -v curl >/dev/null 2>&1 || return 1
  curl -fsS --max-time "${NIXLPER_UPDATE_TIMEOUT:-2}" -o /dev/null "https://github.com" 2>/dev/null
}

# Echo a field from the installed version file (e.g. "VERSION:" or "COMMIT:"), empty if absent.
function _i_installed_version_field() {
  local -r field="$1"
  local -r version_file="${NIXLPER_INSTALL_DIR}/version"
  [[ -f "${version_file}" ]] || return 0
  grep -m1 "^${field}" "${version_file}" 2>/dev/null | sed "s/^${field}[[:space:]]*//"
}

# Latest published (non-prerelease) release tag, empty on failure.
# Note: -f is intentionally omitted — api.github.com returns 403 on unauthenticated
# root requests in some environments, but individual endpoint responses are 200 and valid.
function _i_remote_latest_tag() {
  curl -sSL --max-time "${NIXLPER_UPDATE_TIMEOUT:-2}" \
    "https://api.github.com/repos/${NIXLPER_GITHUB_REPO}/releases/latest" 2>/dev/null \
    | grep '"tag_name"' \
    | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/'
}

# Commit SHA that the rolling edge pre-release was built from (its target_commitish),
# empty on failure. Using the release SHA — not the raw HEAD of main — means
# "update available" is only shown when a new build is actually downloadable.
function _i_remote_edge_release_commit() {
  curl -sSL --max-time "${NIXLPER_UPDATE_TIMEOUT:-2}" \
    "https://api.github.com/repos/${NIXLPER_GITHUB_REPO}/releases/tags/edge" 2>/dev/null \
    | grep -m1 '"target_commitish"' \
    | sed -E 's/.*"target_commitish":[[:space:]]*"([^"]+)".*/\1/'
}

# Return 0 if $1 is a strictly greater version than $2 (version sort), avoiding false
# "downgrade" suggestions when a dev/edge build runs on the stable channel.
function _i_version_gt() {
  [[ "$1" != "$2" ]] && [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" == "$1" ]]
}

# Return 0 if an automatic check is due (throttle elapsed or no prior check).
function _i_update_check_due() {
  local -r cache_file="$(_i_update_cache_file)"
  local -r interval="${NIXLPER_UPDATE_CHECK_INTERVAL:-86400}"
  [[ -f "${cache_file}" ]] || return 0
  local last
  last=$(cat "${cache_file}" 2>/dev/null)
  [[ "${last}" =~ ^[0-9]+$ ]] || return 0
  (( $(date +%s) - last >= interval ))
}

# Stamp the cache file with the current time so we don't re-check until the interval elapses.
function _i_update_touch_cache() {
  local -r cache_file="$(_i_update_cache_file)"
  mkdir -p "$(dirname "${cache_file}")" 2>/dev/null
  date +%s > "${cache_file}" 2>/dev/null || true
}

# Detect how nixlper was installed: "rpm", "deb", or "manual".
function _i_detect_install_method() {
  if rpm -q nixlper &>/dev/null 2>&1; then
    echo "rpm"
  elif dpkg -l nixlper &>/dev/null 2>&1; then
    echo "deb"
  else
    echo "manual"
  fi
}

# Echo the update command appropriate for the given channel and install method.
# $1 = channel (stable|edge), $2 = install method (rpm|deb|manual), $3 = tag (stable only)
function _i_update_command() {
  local -r channel="${1:-stable}"
  local -r method="${2:-manual}"
  local -r tag="${3:-}"
  local -r base="https://github.com/${NIXLPER_GITHUB_REPO}/releases/download"
  case "${method}" in
    rpm)
      if [[ "${channel}" == "edge" ]]; then
        echo "sudo dnf upgrade -y ${base}/edge/nixlper-edge.rpm"
      else
        local rpm_ver="${tag#v}"
        rpm_ver="${rpm_ver//-/_}"
        echo "sudo dnf upgrade -y ${base}/${tag}/nixlper-${rpm_ver}-1.noarch.rpm"
      fi
      ;;
    deb)
      if [[ "${channel}" == "edge" ]]; then
        echo "curl -fsSL -o /tmp/nixlper-edge.deb ${base}/edge/nixlper-edge.deb && sudo dpkg -i /tmp/nixlper-edge.deb"
      else
        echo "curl -fsSL -o /tmp/nixlper-${tag}_all.deb ${base}/${tag}/nixlper-${tag}_all.deb && sudo dpkg -i /tmp/nixlper-${tag}_all.deb"
      fi
      ;;
    *)
      if [[ "${channel}" == "edge" ]]; then
        echo "curl -fsSL https://raw.githubusercontent.com/${NIXLPER_GITHUB_REPO}/main/install.sh | bash -s -- --channel edge"
      else
        echo "curl -fsSL https://raw.githubusercontent.com/${NIXLPER_GITHUB_REPO}/main/install.sh | bash"
      fi
      ;;
  esac
}

# Optional opt-in auto-update (NIXLPER_UPDATE_AUTO=true). $1 = channel flag for install.sh.
function _i_maybe_auto_update() {
  local -r channel="${1:-stable}"
  [[ "${NIXLPER_UPDATE_AUTO:-false}" == "true" ]] || return 0
  local -r method=$(_i_detect_install_method)
  echo "⬆️  NIXLPER_UPDATE_AUTO is on — updating to the latest ${channel} build..."
  case "${method}" in
    rpm)
      local -r base="https://github.com/${NIXLPER_GITHUB_REPO}/releases/download"
      if [[ "${channel}" == "edge" ]]; then
        sudo dnf upgrade -y "${base}/edge/nixlper-edge.rpm"
      fi
      ;;
    deb)
      local -r base="https://github.com/${NIXLPER_GITHUB_REPO}/releases/download"
      if [[ "${channel}" == "edge" ]]; then
        curl -fsSL -o /tmp/nixlper-edge.deb "${base}/edge/nixlper-edge.deb" \
          && sudo dpkg -i /tmp/nixlper-edge.deb
      fi
      ;;
    *)
      if ! command -v curl >/dev/null 2>&1; then
        echo "⚠️  NIXLPER_UPDATE_AUTO is on but curl is missing — skipping auto-update."
        return 0
      fi
      curl -fsSL "https://raw.githubusercontent.com/${NIXLPER_GITHUB_REPO}/main/install.sh" \
        | bash -s -- --yes --channel "${channel}"
      ;;
  esac
}

#-----------------------------------------------------------------------------------------------------------------------
# Channel checks
#-----------------------------------------------------------------------------------------------------------------------
function _i_check_stable() {
  local -r force="${1:-false}"
  local installed latest
  installed=$(_i_installed_version_field "VERSION:")
  latest=$(_i_remote_latest_tag)

  if [[ -z "${latest}" ]]; then
    [[ "${force}" == "true" ]] && echo "⚠️  Could not determine the latest release."
    return 0
  fi

  if [[ -z "${installed}" ]]; then
    [[ "${force}" == "true" ]] && echo "🔔 Latest release is ${latest} (installed version unknown)."
    return 0
  fi

  # Guard: if the installed value doesn't look like a semver tag (e.g. it's "edge"),
  # the stable check is meaningless — skip silently to avoid a false positive.
  if [[ ! "${installed}" =~ ^v?[0-9]+\.[0-9]+ ]]; then
    [[ "${force}" == "true" ]] && echo "ℹ️  Installed build ('${installed}') is not a stable release — skipping stable channel check."
    return 0
  fi

  if _i_version_gt "${latest}" "${installed}"; then
    local method
    method=$(_i_detect_install_method)
    local cmd
    cmd=$(_i_update_command stable "${method}" "${latest}")
    echo "🔔 Nixlper ${latest} is available (you have ${installed})."
    echo "   Update: ${cmd}"
    _i_maybe_auto_update stable
  else
    [[ "${force}" == "true" ]] && echo "✅ Nixlper is up to date (${installed})."
  fi
}

function _i_check_edge() {
  local -r force="${1:-false}"
  local installed latest
  installed=$(_i_installed_version_field "COMMIT:")
  latest=$(_i_remote_edge_release_commit)

  if [[ -z "${latest}" ]]; then
    [[ "${force}" == "true" ]] && echo "⚠️  Could not determine the latest commit."
    return 0
  fi

  if [[ -z "${installed}" ]]; then
    [[ "${force}" == "true" ]] && echo "🔔 Latest commit is ${latest:0:7} (installed commit unknown)."
    return 0
  fi

  if [[ "${installed}" == "${latest}" ]]; then
    [[ "${force}" == "true" ]] && echo "✅ Nixlper is at the latest commit (${latest:0:7})."
  else
    local method
    method=$(_i_detect_install_method)
    local cmd
    cmd=$(_i_update_command edge "${method}")
    echo "🔔 A newer Nixlper commit is available (${latest:0:7}, you have ${installed:0:7})."
    echo "   Update: ${cmd}"
    _i_maybe_auto_update edge
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Public entry points
#-----------------------------------------------------------------------------------------------------------------------
# Core checker. $1 = "true" to force (bypass throttle and speak even when up to date).
function _i_check_for_updates() {
  local -r force="${1:-false}"
  local -r channel="${NIXLPER_UPDATE_CHANNEL:-stable}"

  if [[ "${channel}" == "off" || "${NIXLPER_UPDATE_CHECK:-true}" == "false" ]]; then
    [[ "${force}" == "true" ]] && echo "ℹ️  Update checks are disabled (channel=off or NIXLPER_UPDATE_CHECK=false)."
    return 0
  fi

  if [[ "${force}" != "true" ]] && ! _i_update_check_due; then
    return 0
  fi

  if ! _i_is_online; then
    [[ "${force}" == "true" ]] && echo "📡 Internet not reachable — update check skipped."
    return 0
  fi

  # Stamp now so a failed lookup still respects the throttle and we don't hammer GitHub.
  _i_update_touch_cache

  case "${channel}" in
    stable) _i_check_stable "${force}" ;;
    edge)   _i_check_edge "${force}" ;;
    *)      [[ "${force}" == "true" ]] && echo "⚠️  Unknown NIXLPER_UPDATE_CHANNEL='${channel}' (use stable|edge|off)." ;;
  esac
}

# @cmd-palette
# @description: Check for a newer Nixlper version on the active update channel
# @category: Updates
# @keybind: CTRL+X+W
# @alias: nu
function _check_update() {
  _i_check_for_updates true
}

# Fetch the body text of the edge pre-release from GitHub API, empty on failure.
function _i_fetch_edge_release_body() {
  curl -sSL --max-time "${NIXLPER_UPDATE_TIMEOUT:-2}" \
    "https://api.github.com/repos/${NIXLPER_GITHUB_REPO}/releases/tags/edge" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('body',''))" 2>/dev/null
}

# @cmd-palette
# @description: Show ongoing work planned for the next release (fetched from edge build notes)
# @category: Updates
# @keybind: CTRL+X+G
# @alias: nw
function show_ongoing_work() {
  if ! _i_is_online; then
    echo "📡 Internet not reachable — cannot fetch ongoing work."
    return 1
  fi
  echo "🚧 Fetching ongoing work from edge release..."
  local body
  body=$(_i_fetch_edge_release_body)
  if [[ -z "${body}" ]]; then
    echo "⚠️  Could not fetch edge release notes."
    return 1
  fi
  echo ""
  echo "${body}"
}
