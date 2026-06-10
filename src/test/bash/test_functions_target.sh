#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_target.sh
# DESCRIPTION: Unit tests for the target staging feature (functions_target.sh).
#
# Pure bash, no external framework. All state is isolated to temp dirs so tests
# never touch a real installation or /tmp/nixlper_target.
# Run locally with:  bash src/test/bash/test_functions_target.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_target.sh"

# Stub _i_log_as_error so we can source the module without the logging module
function _i_log_as_error() { echo "ERROR: $*" >&2; }

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Isolated temp environment — nothing written outside these dirs
TEST_DIR="$(mktemp -d)"
export NIXLPER_TARGET_DIR="${TEST_DIR}/target"
export NIXLPER_MARKS_FILE="${TEST_DIR}/marks"
trap 'rm -rf "${TEST_DIR}"' EXIT

# shellcheck source=/dev/null
source "${MODULE}"

#-----------------------------------------------------------------------------------------------------------------------
# Helpers
#-----------------------------------------------------------------------------------------------------------------------
PASS=0
FAIL=0

_expect_eq() {
  local -r name="$1" got="$2" want="$3"
  if [[ "${got}" == "${want}" ]]; then
    echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: got [${got}] want [${want}]"; FAIL=$((FAIL + 1))
  fi
}

_expect_true() {
  local -r name="$1"; shift
  if "$@"; then echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else echo "  ❌ ${name}: expected success, got failure"; FAIL=$((FAIL + 1)); fi
}

_expect_false() {
  local -r name="$1"; shift
  if ! "$@"; then echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else echo "  ❌ ${name}: expected failure, got success"; FAIL=$((FAIL + 1)); fi
}

_make_file() {
  local path="$1"
  mkdir -p "$(dirname "${path}")"
  echo "content" > "${path}"
}

_reset() {
  rm -rf "${NIXLPER_TARGET_DIR}" "${NIXLPER_MARKS_FILE}"
}

#-----------------------------------------------------------------------------------------------------------------------
# target_copy
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_copy ==="

_reset
src="${TEST_DIR}/file_a.txt"
_make_file "${src}"
target_copy "${src}" > /dev/null
_expect_true  "copy: dest file exists"            test -f "${NIXLPER_TARGET_DIR}/file_a.txt"
perms=$(stat -c "%a" "${NIXLPER_TARGET_DIR}/file_a.txt")
_expect_eq    "copy: dest file is 644"            "${perms}" "644"

_reset
_expect_false "copy: missing arg returns error"   target_copy

_reset
_expect_false "copy: non-existent file returns error" target_copy "/no/such/file.txt"

#-----------------------------------------------------------------------------------------------------------------------
# target_mark / target_list_marks
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_mark / target_list_marks ==="

_reset
f1="${TEST_DIR}/mark1.sh"
f2="${TEST_DIR}/mark2.sh"
_make_file "${f1}"
_make_file "${f2}"

target_mark "${f1}" > /dev/null
_expect_eq   "mark: marks file added"             "$(wc -l < "${NIXLPER_MARKS_FILE}")" "1"

target_mark "${f1}" > /dev/null  # duplicate
_expect_eq   "mark: duplicate is no-op"           "$(wc -l < "${NIXLPER_MARKS_FILE}")" "1"

target_mark "${f2}" > /dev/null
_expect_eq   "mark: second file added"            "$(wc -l < "${NIXLPER_MARKS_FILE}")" "2"

_expect_false "mark: non-existent file returns error" target_mark "/no/such.txt"

list_out=$(target_list_marks)
_expect_eq   "list: shows 2 entries"              "$(echo "${list_out}" | grep -c "mark[12]")" "2"

#-----------------------------------------------------------------------------------------------------------------------
# target_clear_marks
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_clear_marks ==="

_reset
_make_file "${TEST_DIR}/x.txt"
target_mark "${TEST_DIR}/x.txt" > /dev/null
target_clear_marks > /dev/null
_expect_false "clear_marks: marks file removed"   test -f "${NIXLPER_MARKS_FILE}"

# idempotent — no marks file
target_clear_marks > /dev/null
_expect_true  "clear_marks: no-op when no marks"  true

#-----------------------------------------------------------------------------------------------------------------------
# target_unmark (numbered removal)
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_unmark ==="

_reset
fa="${TEST_DIR}/ua.txt"
fb="${TEST_DIR}/ub.txt"
_make_file "${fa}"; _make_file "${fb}"
target_mark "${fa}" > /dev/null
target_mark "${fb}" > /dev/null

# simulate user typing "1" then Enter
echo "1" | target_unmark > /dev/null
_expect_eq   "unmark: one entry removed"          "$(wc -l < "${NIXLPER_MARKS_FILE}")" "1"
remaining=$(cat "${NIXLPER_MARKS_FILE}")
_expect_eq   "unmark: remaining entry is second file" "${remaining}" "$(realpath "${fb}")"

# simulate user typing "q"
echo "q" | target_unmark > /dev/null
_expect_eq   "unmark: q leaves list unchanged"    "$(wc -l < "${NIXLPER_MARKS_FILE}")" "1"

#-----------------------------------------------------------------------------------------------------------------------
# target_pack
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_pack ==="

_reset
p1="${TEST_DIR}/pack1.conf"
p2="${TEST_DIR}/pack2.conf"
_make_file "${p1}"; _make_file "${p2}"
target_mark "${p1}" > /dev/null
target_mark "${p2}" > /dev/null

target_pack > /dev/null
tgz=$(find "${NIXLPER_TARGET_DIR}" -name "nixlper_pack_*.tgz" | head -1)
_expect_true  "pack: tgz created"                 test -f "${tgz}"
tgz_perms=$(stat -c "%a" "${tgz}")
_expect_eq    "pack: tgz is 644"                  "${tgz_perms}" "644"
_expect_false "pack: marks cleared after pack"    test -f "${NIXLPER_MARKS_FILE}"

# verify archive contains both files
members=$(tar -tzf "${tgz}" 2>/dev/null)
_expect_eq    "pack: archive contains pack1.conf" "$(echo "${members}" | grep -c "pack1.conf")" "1"
_expect_eq    "pack: archive contains pack2.conf" "$(echo "${members}" | grep -c "pack2.conf")" "1"

# no marks → graceful exit
_reset
out=$(target_pack)
_expect_eq    "pack: no marks exits cleanly"      "$(echo "${out}" | grep -c "No marked")" "1"

#-----------------------------------------------------------------------------------------------------------------------
# target_set
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_set ==="

_reset
original="${NIXLPER_TARGET_DIR}"
target_set "${TEST_DIR}/new_target" > /dev/null
_expect_eq   "set: NIXLPER_TARGET_DIR updated"    "${NIXLPER_TARGET_DIR}" "${TEST_DIR}/new_target"
export NIXLPER_TARGET_DIR="${original}"  # restore

#-----------------------------------------------------------------------------------------------------------------------
# target_clean
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== target_clean ==="

_reset
_i_target_ensure_dir
_make_file "${NIXLPER_TARGET_DIR}/todel.txt"

echo "y" | target_clean > /dev/null
_expect_eq   "clean: target dir empty after y"    "$(find "${NIXLPER_TARGET_DIR}" -maxdepth 1 -mindepth 1 | wc -l)" "0"

_make_file "${NIXLPER_TARGET_DIR}/keep.txt"
echo "n" | target_clean > /dev/null
_expect_eq   "clean: file kept after n"           "$(find "${NIXLPER_TARGET_DIR}" -maxdepth 1 -mindepth 1 | wc -l)" "1"

#-----------------------------------------------------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "========================================"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "========================================"
[[ "${FAIL}" -eq 0 ]]
