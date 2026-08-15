#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_syshealth.sh
# DESCRIPTION: Unit tests for the system health advisor (functions_syshealth.sh).
#
# Pure bash, no external framework. Run with: bash src/test/bash/test_functions_syshealth.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_syshealth.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${MODULE}"

PASS=0
FAIL=0

_expect_eq() {
  local -r name="$1" got="$2" want="$3"
  if [[ "${got}" == "${want}" ]]; then
    echo "  ✅ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: got [${got}] want [${want}]"
    FAIL=$((FAIL + 1))
  fi
}

_expect_contains() {
  local -r name="$1" haystack="$2" needle="$3"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    echo "  ✅ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: expected [${needle}] in [${haystack}]"
    FAIL=$((FAIL + 1))
  fi
}

_expect_not_contains() {
  local -r name="$1" haystack="$2" needle="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "  ✅ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: [${needle}] should not be in [${haystack}]"
    FAIL=$((FAIL + 1))
  fi
}

########################################################################################################################
echo "--- _i_health_level ---"
########################################################################################################################

unset NIXLPER_HEALTH_WARN_PCT NIXLPER_HEALTH_CRIT_PCT NIXLPER_HEALTH_TOP_N

_expect_eq "below default warn (79%) is OK"   "$(_i_health_level 79)" "OK"
_expect_eq "at default warn (80%) is WARN"    "$(_i_health_level 80)" "WARN"
_expect_eq "between warn/crit (89%) is WARN"  "$(_i_health_level 89)" "WARN"
_expect_eq "at default crit (90%) is CRIT"    "$(_i_health_level 90)" "CRIT"
_expect_eq "above crit (100%) is CRIT"        "$(_i_health_level 100)" "CRIT"

NIXLPER_HEALTH_WARN_PCT=50
NIXLPER_HEALTH_CRIT_PCT=60
_expect_eq "respects custom WARN threshold" "$(_i_health_level 55)" "WARN"
_expect_eq "respects custom CRIT threshold" "$(_i_health_level 60)" "CRIT"
unset NIXLPER_HEALTH_WARN_PCT NIXLPER_HEALTH_CRIT_PCT

########################################################################################################################
echo "--- _i_health_print ---"
########################################################################################################################

_expect_eq "OK line format"   "$(_i_health_print OK "all good")"   "[OK]   all good"
_expect_eq "WARN line format" "$(_i_health_print WARN "careful")"  "[WARN] careful"
_expect_eq "CRIT line format" "$(_i_health_print CRIT "trouble")"  "[CRIT] trouble"

########################################################################################################################
echo "--- _i_health_join ---"
########################################################################################################################

_expect_eq "joins multiple items with separator" "$(_i_health_join ", " "a" "b" "c")" "a, b, c"
_expect_eq "single item returns itself"           "$(_i_health_join ", " "a")"          "a"
_expect_eq "no items returns empty string"         "$(_i_health_join ", ")"              ""

########################################################################################################################
echo "--- _i_health_check_memory ---"
########################################################################################################################

free() { printf "              total        used        free\n"; printf "Mem:          16000       14000        2000\n"; }
ps() { :; }
out=$(_i_health_check_memory)
_expect_contains "flags high memory usage as WARN" "${out}" "[WARN]"
_expect_contains "reports computed percentage"      "${out}" "87%"
_expect_contains "reports used/total MB"            "${out}" "14000MB / 16000MB"
_expect_contains "suggests remediation"             "${out}" "consider: ik or kill -9 <pid>"

free() { printf "              total        used        free\n"; printf "Mem:          16000       2000       14000\n"; }
out=$(_i_health_check_memory)
_expect_contains "low memory usage is OK"       "${out}" "[OK]"
_expect_not_contains "OK line has no remediation" "${out}" "consider:"

free() { printf "              total        used        free\n"; printf "Mem:          16000       14000        2000\n"; }
ps() { printf "1234 java 1024000\n"; }
out=$(_i_health_check_memory)
_expect_contains "includes top consumer name" "${out}" "java"
_expect_contains "includes top consumer pid"  "${out}" "pid 1234"

unset -f free

########################################################################################################################
echo "--- _i_health_check_disk ---"
########################################################################################################################

df() {
  if [[ "$1" == "-P" && "${2:-}" == "-T" ]]; then
    printf "Filesystem     Type  1024-blocks   Used Available Capacity Mounted on\n"
    printf "/dev/sda1      ext4    100000000  95000000  5000000      95%% /\n"
    printf "tmpfs          tmpfs      100000     1000    99000       1%% /run\n"
  fi
}
out=$(_i_health_check_disk)
_expect_contains "flags high disk usage as CRIT" "${out}" "[CRIT]"
_expect_contains "reports mount point"            "${out}" "Disk / at 95%"
_expect_not_contains "excludes tmpfs mounts"       "${out}" "/run"

df() {
  if [[ "$1" == "-P" && "${2:-}" == "-T" ]]; then
    printf "Filesystem     Type  1024-blocks   Used Available Capacity Mounted on\n"
    printf "/dev/sda1      ext4    100000000  30000000  70000000      30%% /\n"
  fi
}
out=$(_i_health_check_disk)
_expect_contains "low disk usage is OK" "${out}" "[OK]"

# df -T unsupported (e.g. busybox) — falls back to type-less parsing
df() {
  if [[ "$1" == "-P" && "${2:-}" == "-T" ]]; then
    return 1
  fi
  printf "Filesystem     1024-blocks   Used Available Capacity Mounted on\n"
  printf "/dev/sda1        100000000  95000000  5000000      95%% /\n"
}
out=$(_i_health_check_disk)
_expect_contains "falls back when df -T unsupported" "${out}" "[CRIT]"
_expect_contains "root mount du suggestion has no double slash" "${out}" "du -sh /* "

unset -f df

########################################################################################################################
echo "--- _i_health_check_cpu ---"
########################################################################################################################

uptime() { echo " 12:00:00 up 3 days,  2:14,  2 users,  load average: 3.50, 3.20, 3.10"; }
nproc() { echo 4; }
ps() { :; }
out=$(_i_health_check_cpu)
_expect_contains "flags high load as WARN" "${out}" "[WARN]"
_expect_contains "reports load average"     "${out}" "load 3.50"
_expect_contains "reports core count"       "${out}" "4 core(s)"

uptime() { echo " 12:00:00 up 3 days,  2:14,  2 users,  load average: 0.10, 0.20, 0.10"; }
out=$(_i_health_check_cpu)
_expect_contains "low load is OK" "${out}" "[OK]"

unset -f uptime nproc ps

########################################################################################################################
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
