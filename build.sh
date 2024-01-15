#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: build.sh                                                             #
#                                           DESCRIPTION: sh to build the Nixlper package, alternative to Gradle        #
########################################################################################################################
set -o nounset
set -o errexit
set -o pipefail

CURRENT_FOLDER=$(dirname $0)
if [[ "${CURRENT_FOLDER}" == "." ]]; then
  CURRENT_FOLDER=$(pwd)
fi

readonly PROJECT_NAME=$(sed 's/.* "\(.*\)"/\1/g' settings.gradle.kts)
readonly PROJECT_VERSION=$(grep "version =" build.gradle.kts | sed 's/.* "\(.*\)"/\1/g')

readonly SHORT_SHA=$(git log -n 1 --pretty=format:%h)
readonly LAST_COMMIT_DATE=$(git log -n 1 --pretty=format:%ad --date=format:'%Y-%m-%d')


function _init_folders() {
  rm -rf "${CURRENT_FOLDER}"/build/distributions
  rm -rf "${CURRENT_FOLDER}"/build/work
  mkdir -p "${CURRENT_FOLDER}"/build/distributions
  mkdir -p "${CURRENT_FOLDER}"/build/work/help
}

function _make_tar_archive() {
  cd "${CURRENT_FOLDER}"/build/work
  tar -cf ../distributions/"${PROJECT_NAME}"-"${PROJECT_VERSION}".tar -- *
}

function _prepare_package() {
  cp -f src/main/bash/nixlper.sh "${CURRENT_FOLDER}"/build/work

  cp -f src/main/template/version.template "${CURRENT_FOLDER}"/build/work/version
  sed -i "s/\${project.name}/${PROJECT_NAME}/g" "${CURRENT_FOLDER}"/build/work/version
  sed -i "s/\${project.version}/${PROJECT_VERSION}/g" "${CURRENT_FOLDER}"/build/work/version
  sed -i "s/\${VERSION_SHA}/${SHORT_SHA}/g" "${CURRENT_FOLDER}"/build/work/version
  sed -i "s/\${VERSION_TIME}/${LAST_COMMIT_DATE}/g" "${CURRENT_FOLDER}"/build/work/version

  cp -f src/main/help/* "${CURRENT_FOLDER}"/build/work/help
  dos2unix "${CURRENT_FOLDER}"/build/work/*.sh
  dos2unix "${CURRENT_FOLDER}"/build/work/help/*
}

function _clean_work_dir() {
  rm -rf "${CURRENT_FOLDER}"/build/work
}

function main() {
  if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--help" ]]; then
      echo "Usage: $0

      sh script will create in build/distributions following files:
      - nixlper-VERSION.tar
      è nixlper-VERSION.zip"
    else
      echo "ERROR: \"$1\" unknown command"
    fi
  fi

  echo "---------------------------------------------------------------------------------------------------------------"
  echo "BuildNixlper archive"
  echo "---------------------------------------------------------------------------------------------------------------"

  echo "Clean and create output dirs"
  _init_folders
  echo "-> DONE"
  echo "Prepare Nixlper package"
  _prepare_package
  echo "-> DONE"
  echo "Create tar archive"
  _make_tar_archive
  echo "-> DONE"
  echo "Clean working dir"
  _clean_work_dir
  echo "-> DONE"
  echo "Build done with success"

}

if main "$@"; then
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Archive lays in ${CURRENT_FOLDER}/build/distributions"
  echo "---------------------------------------------------------------------------------------------------------------"
else
  echo "ERROR: error during Nixlper build"
fi