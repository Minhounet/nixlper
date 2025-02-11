#! /bin/bash

readonly SCRIPT_DIRECTORY=$(dirname "$(realpath "$0")")

testEquality() {
  assertEquals 1 1
}

# any function test
_return_any_string() {
  echo "peppa"
}

testStringEquality() {
  assertEquals "peppa" "$(_return_any_string)"
}

cd "${SCRIPT_DIRECTORY}"
source ../../../lib/shunit2-2.1.8/shunit2
