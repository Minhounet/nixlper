#! /bin/bash

readonly SCRIPT_DIRECTORY=$(dirname "$(realpath "$0")")

function setUp() {
  source ../../main/bash/functions_logging.sh
}

function test_i_log() {
  assertEquals "mockedDate INFO yala" "$(_i_log "INFO" "yala")"
}

function test_i_log_as_info() {
  assertEquals "mockedDate INFO yala" "$(_i_log_as_info "yala")"
}

function test_i_log_as_error() {
  assertEquals "mockedDate ERROR yala" "$(_i_log_as_error "yala")"
}

function test_i_log_action_cancelled() {
  assertEquals "mockedDate INFO Action is cancelled" "$(_i_log_action_cancelled)"
}

# mock
function date() {
  echo "mockedDate"
}

cd "${SCRIPT_DIRECTORY}"
source ../../../lib/shunit2-2.1.8/shunit2
