#!/usr/bin/env bash
########################################################################################################################
# FILE: build.sh
# DESCRIPTION: sh to build the Nixlper package, alternative to Gradle
########################################################################################################################
#***********************************************************************************************************************
# Definitions
#***********************************************************************************************************************
set -o nounset
set -o errexit
set -o pipefail

CURRENT_FOLDER=$(dirname $0)
if [[ "${CURRENT_FOLDER}" == "." ]]; then
  CURRENT_FOLDER=$(pwd)
fi

readonly PROJECT_NAME="nixlper"

readonly BUILD_DIRECTORY=${CURRENT_FOLDER}/build/distributions

readonly WORK_DIRECTORY=${CURRENT_FOLDER}/build/work
readonly WORK_HELP_DIRECTORY=${WORK_DIRECTORY}/help
readonly SHA_VERSION_FILE=${WORK_DIRECTORY}/version
#***********************************************************************************************************************
# Functions
#***********************************************************************************************************************
function _init_folders() {
  rm -rf "${BUILD_DIRECTORY}"
  rm -rf "${WORK_DIRECTORY}"
  mkdir -p "${BUILD_DIRECTORY}"
  mkdir -p "${WORK_HELP_DIRECTORY}"
}

function _clean_work_dir() {
  rm -rf "${CURRENT_FOLDER}"/build/work
}

function _create_sha_version_file() {
  local -r git_tag=$(git describe --tags --exact-match HEAD 2>&1)
  local -r git_time=$(git log -n 1 --pretty=format:%ad --date=format:'%Y-%m-%d')
  local -r git_short_sha=$(git log -n 1 --pretty=format:%h)
  echo "👉 Create version file (git sha)"
  {
    echo "PROJECT: ${PROJECT_NAME}"
    if [[ ! ${git_tag} =~ "fatal:" ]]; then
      echo "VERSION: ${git_tag}"
    fi
    echo "TECHNICAL VERSION: ${git_short_sha} (${git_time})"
  } >> "${SHA_VERSION_FILE}"
  _log_ok
}

function _prepare_package() {
  _create_sha_version_file
  _merge_sh_sources
  cp -f src/main/help/* "${WORK_DIRECTORY}"/help
  dos2unix "${CURRENT_FOLDER}"/build/work/*.sh
  dos2unix "${CURRENT_FOLDER}"/build/work/help/*
}

function _get_archive_path() {
  local git_tag
  git_tag=$(git describe --tags --exact-match HEAD 2>&1)
  if [[ ! ${git_tag} =~ "fatal:" ]]; then
    git_tag="-${git_tag}"
  else
    git_tag=""
  fi
  echo "${BUILD_DIRECTORY}/${PROJECT_NAME}${git_tag}.tar"
}

function _make_tar_archive() {
  local -r archive_path=$(_get_archive_path)
  cd "${CURRENT_FOLDER}"/build/work
  tar -cf "${archive_path}" -- *
}

function _merge_sh_sources() {
  cp src/main/bash/nixlper.sh "${WORK_DIRECTORY}/nixlper.tmp"
  cat src/main/bash/function* >> "${WORK_DIRECTORY}/functions.tmp"

  # Remove comment lines, but preserve ALL annotation lines (any "# @..." comment).
  # This is deliberately generic: the command-palette parser reads @cmd-palette, @description,
  # @category, @keybind, @alias, @template, @args, @interactive — and any annotation added in
  # future. Keeping every "# @..." line means a new annotation never has to be whitelisted here,
  # which previously caused annotations to be silently stripped from built/installed packages.
  # Code lines (which may contain '@' in regexes) start with whitespace, not '#', so the
  # '/^#.*/d' deletion never touches them.
  sed -i '/^#[[:space:]]*@/!{/^#.*/d}' "${WORK_DIRECTORY}/functions.tmp"
  sed -i '/^#[[:space:]]*@/!{/^#.*/d}' "${WORK_DIRECTORY}/nixlper.tmp"

  echo "#!/usr/bin/env bash" > "${WORK_DIRECTORY}/nixlper.sh"
  echo "###############################################################################################################" >> "${WORK_DIRECTORY}/nixlper.sh"
  echo "# file is generated" >> "${WORK_DIRECTORY}/nixlper.sh"
  echo "###############################################################################################################" >> "${WORK_DIRECTORY}/nixlper.sh"
  echo "# FUNCTIONS" >> "${WORK_DIRECTORY}/nixlper.sh"
  cat "${WORK_DIRECTORY}/functions.tmp" >> "${WORK_DIRECTORY}/nixlper.sh"
  echo "###############################################################################################################" >> "${WORK_DIRECTORY}/nixlper.sh"
  echo "# MAIN" >> "${WORK_DIRECTORY}/nixlper.sh"
  echo "###############################################################################################################" >> "${WORK_DIRECTORY}/nixlper.sh"
  cat "${WORK_DIRECTORY}/nixlper.tmp" >> "${WORK_DIRECTORY}/nixlper.sh"
  rm -f "${WORK_DIRECTORY}/nixlper.tmp" "${WORK_DIRECTORY}/functions.tmp"
}

function _log_info() {
  echo "ℹ️ $1"	
}

function _log_ok() {
	echo "👍"
	echo ""
}

function _log_error() {
	echo "🔴 $1"
	return 1
}

function _log_separator() {
  echo "====================================================================================================="
}

#***********************************************************************************************************************
# Entry point
#***********************************************************************************************************************
function main() {
  if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--help" ]]; then
      echo "Usage: $0
      sh script will create in nixlper.tar in build/distributions directory"
    else
      _log_error "\"$1\" unknown command "
    fi
  fi

  _log_separator
  _log_info "Build Nixlper archive"
  _log_separator

  _log_info "Clean and create output dirs"
  _init_folders
  _log_ok
  _log_info "Prepare Nixlper package"
  _prepare_package
  _log_ok
  _log_info "Create tar archive"
  _make_tar_archive
  _log_ok
  _log_info "Clean working dir"
  _clean_work_dir
  _log_ok
  echo "Build done with success"
  _log_separator
}

if main "$@"; then
  _log_separator
  _log_info "Archive lays in ${CURRENT_FOLDER}/build/distributions"
  _log_separator
else
  _log_error "ERROR: error during Nixlper build"
fi
