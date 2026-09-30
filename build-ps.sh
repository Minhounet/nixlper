#!/usr/bin/env bash
########################################################################################################################
# FILE: build-ps.sh
# DESCRIPTION: package the PowerShell port (src/main/powershell/Nixlper) as a zip, ready to unzip into a PowerShell
#              modules folder: build/distributions/nixlper-powershell-<VERSION>.zip
#
# The zip contains a single top-level "Nixlper/" folder (module manifest, sources, version file), so after
# extraction into e.g. Documents\PowerShell\Modules, `Import-Module Nixlper` works with no path.
#
# Version: when HEAD carries a tag, the zip is named after it, like the bash tar (otherwise after the short commit
# SHA). A plain vX.Y.Z tag is also stamped into ModuleVersion of the packaged Nixlper.psd1; other tags (v2.6.0-rc1)
# keep the source ModuleVersion, because a manifest version must be purely numeric.
#
# Unlike build.sh, this never wipes build/distributions: the release workflow runs it after the tar/RPM/DEB builds.
########################################################################################################################
set -o nounset
set -o errexit
set -o pipefail

CURRENT_FOLDER=$(cd "$(dirname "$0")" && pwd)
readonly CURRENT_FOLDER
readonly MODULE_SOURCE="${CURRENT_FOLDER}/src/main/powershell/Nixlper"
readonly BUILD_DIRECTORY="${CURRENT_FOLDER}/build/distributions"
readonly WORK_DIRECTORY="${CURRENT_FOLDER}/build/work-powershell"

function _log_ok() {
  echo "✅ OK"
}

function _fail() {
  echo "❌ $1" >&2
  exit 1
}

command -v zip >/dev/null 2>&1 || _fail "zip is required (apt-get install zip)"
[[ -f "${MODULE_SOURCE}/Nixlper.psd1" ]] || _fail "Module manifest not found: ${MODULE_SOURCE}/Nixlper.psd1"

cd "${CURRENT_FOLDER}"
git_tag=$(git describe --tags --exact-match HEAD 2>/dev/null || true)
git_time=$(git log -n 1 --pretty=format:%ad --date=format:'%Y-%m-%d')
git_short_sha=$(git log -n 1 --pretty=format:%h)
git_sha=$(git log -n 1 --pretty=format:%H)

# ModuleVersion must be a plain numeric version (System.Version), so only vX.Y.Z tags are stamped.
# The zip is always named after the tag when there is one (the release workflow uploads it by tag name).
module_version=""
archive_suffix="${git_short_sha}"
if [[ -n "${git_tag}" ]]; then
  archive_suffix="${git_tag}"
fi
if [[ "${git_tag}" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  module_version="${BASH_REMATCH[1]}"
fi
readonly ARCHIVE="${BUILD_DIRECTORY}/nixlper-powershell-${archive_suffix}.zip"

echo "👉 Prepare work directory"
rm -rf "${WORK_DIRECTORY}"
mkdir -p "${WORK_DIRECTORY}" "${BUILD_DIRECTORY}"
cp -R "${MODULE_SOURCE}" "${WORK_DIRECTORY}/Nixlper"
_log_ok

if [[ -n "${module_version}" ]]; then
  echo "👉 Stamp ModuleVersion ${module_version}"
  sed -i -E "s/^([[:space:]]*ModuleVersion[[:space:]]*=[[:space:]]*)'[^']*'/\1'${module_version}'/" \
    "${WORK_DIRECTORY}/Nixlper/Nixlper.psd1"
  grep -q "ModuleVersion *= *'${module_version}'" "${WORK_DIRECTORY}/Nixlper/Nixlper.psd1" \
    || _fail "Could not stamp ModuleVersion in the manifest"
  _log_ok
fi

echo "👉 Create version file (git sha)"
{
  echo "PROJECT: nixlper-powershell"
  [[ -n "${git_tag}" ]] && echo "VERSION: ${git_tag}"
  echo "TECHNICAL VERSION: ${git_short_sha} (${git_time})"
  echo "COMMIT: ${git_sha}"
} > "${WORK_DIRECTORY}/Nixlper/version"
_log_ok

# Windows PowerShell 5.1 reads BOM-less .ps1 files as ANSI: refuse to ship anything non-ASCII (see CLAUDE.md).
echo "👉 Check sources are pure ASCII"
if LC_ALL=C grep -rlP '[^\x00-\x7F]' "${WORK_DIRECTORY}/Nixlper" --include='*.ps1' --include='*.psm1' --include='*.psd1'; then
  _fail "Non-ASCII characters found in the files above"
fi
_log_ok

echo "👉 Create ${ARCHIVE#"${CURRENT_FOLDER}"/}"
rm -f "${ARCHIVE}"
(cd "${WORK_DIRECTORY}" && zip -qr -X "${ARCHIVE}" Nixlper)
rm -rf "${WORK_DIRECTORY}"
_log_ok
