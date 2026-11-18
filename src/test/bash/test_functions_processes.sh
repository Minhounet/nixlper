#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_processes.sh
# DESCRIPTION: Offline unit tests for the process feature (functions_processes.sh), focused on the
# unified fuzzy kill picker.
#
# Pure bash, no external framework, no dependency on ss/netstat/ps being present or on any real
# process being alive: the socket parsers are fed canned tool output, and _i_kill_ports_map / ps
# are overridden with mocks.
# Run locally with:
#   bash src/test/bash/test_functions_processes.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_processes.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

# Stub logging functions used by the module.
_i_log_as_info()  { :; }
_i_log_as_error() { :; }

# shellcheck source=/dev/null
source "${MODULE}"

#-----------------------------------------------------------------------------------------------------------------------
# Assertion helpers
#-----------------------------------------------------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------------------------------------------------
# Tests: ss parsing
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== processes: _i_kill_parse_ss_ports ==="

_SS_SAMPLE='State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("java",pid=1234,fd=50))
LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=22,fd=6),("nginx",pid=23,fd=6))
LISTEN 0      4096       127.0.0.1:5432       0.0.0.0:*'

result=$(printf '%s\n' "${_SS_SAMPLE}" | _i_kill_parse_ss_ports)
_expect_eq "ss: header line produces no entry" "$(printf '%s\n' "${result}" | wc -l | tr -d ' ')" "3"
_expect_eq "ss: IPv4 socket maps pid to port" "$(printf '%s\n' "${result}" | sed -n 1p)" "1234 8080"
_expect_eq "ss: IPv6 socket keeps only the port, not the [::] address" "$(printf '%s\n' "${result}" | sed -n 2p)" "22 80"
_expect_eq "ss: second pid of the same socket is emitted too" "$(printf '%s\n' "${result}" | sed -n 3p)" "23 80"
_expect_eq "ss: socket without a pid= (other user) is skipped" "$(printf '%s\n' "${result}" | grep -c '5432')" "0"

#-----------------------------------------------------------------------------------------------------------------------
# Tests: netstat parsing
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== processes: _i_kill_parse_netstat_ports ==="

_NETSTAT_SAMPLE='Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      1234/java
tcp6       0      0 :::80                   :::*                    LISTEN      22/nginx
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -'

result=$(printf '%s\n' "${_NETSTAT_SAMPLE}" | _i_kill_parse_netstat_ports)
_expect_eq "netstat: only rows owning a PID are kept" "$(printf '%s\n' "${result}" | wc -l | tr -d ' ')" "2"
_expect_eq "netstat: IPv4 row maps pid to port" "$(printf '%s\n' "${result}" | sed -n 1p)" "1234 8080"
_expect_eq "netstat: IPv6 row maps pid to port" "$(printf '%s\n' "${result}" | sed -n 2p)" "22 80"
_expect_eq "netstat: '-' row is not parsed as a pid" "$(printf '%s\n' "${result}" | grep -c '^-')" "0"

#-----------------------------------------------------------------------------------------------------------------------
# Tests: candidate lines
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== processes: _i_kill_candidates ==="

# Mock the socket map: pid 1234 listens twice on 8080 (IPv4 + IPv6) and once on 9090.
_i_kill_ports_map() {
  printf '%s\n' "1234 8080" "1234 8080" "1234 9090" "22 80"
}

# Mock ps: includes the current shell (must be filtered out) and the picker's own ps invocation.
ps() {
  printf '%s\n' \
    " 1234 user     java -jar my app.jar" \
    "   22 root     nginx: master process" \
    " 5678 user     node worker.js" \
    "  $$ me       bash" \
    " 9999 user     ps -eo ${_NIXLPER_KILL_PS_FORMAT}"
}

result=$(_i_kill_candidates)
_expect_eq "candidates: own shell and own ps are filtered out" "$(printf '%s\n' "${result}" | wc -l | tr -d ' ')" "3"
_expect_eq "candidates: ports are joined and de-duplicated" \
  "$(printf '%s\n' "${result}" | awk '$1 == 1234 {print $2}')" ":8080,:9090"
_expect_eq "candidates: process without a listening socket shows a dash" \
  "$(printf '%s\n' "${result}" | awk '$1 == 5678 {print $2}')" "-"
_expect_eq "candidates: command line containing spaces is kept intact" \
  "$(printf '%s\n' "${result}" | awk '$1 == 1234 { $1=""; $2=""; $3=""; sub(/^ +/, ""); print }')" "java -jar my app.jar"
_expect_eq "candidates: user column is preserved" \
  "$(printf '%s\n' "${result}" | awk '$1 == 22 {print $3}')" "root"
_expect_eq "candidates: pid is the first field, so a selected line maps back with \${line%% *}" \
  "$(line=$(printf '%s\n' "${result}" | sed -n 1p); echo "${line%% *}")" "1234"

#-----------------------------------------------------------------------------------------------------------------------
# Tests: fuzzy mode toggle
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== processes: _i_kill_fuzzy_enabled ==="

# fzf presence is irrelevant when the feature is explicitly disabled.
NIXLPER_KILL_FUZZY=false
if _i_kill_fuzzy_enabled; then enabled="yes"; else enabled="no"; fi
_expect_eq "fuzzy: disabled by NIXLPER_KILL_FUZZY=false" "${enabled}" "no"

# With the flag on, the answer must follow fzf availability.
NIXLPER_KILL_FUZZY=true
if command -v fzf &>/dev/null; then want="yes"; else want="no"; fi
if _i_kill_fuzzy_enabled; then enabled="yes"; else enabled="no"; fi
_expect_eq "fuzzy: enabled by default, gated on fzf being installed" "${enabled}" "${want}"

unset NIXLPER_KILL_FUZZY

#-----------------------------------------------------------------------------------------------------------------------
# Tests: group kill (ik --all PATTERN)
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "=== processes: _i_kill_all_matching ==="

# Fake process table: 3 IntelliJ processes (one with a different case), 1 user literally named
# "idea", and unrelated ones. PIDs 1/2/3 contain digits that must not match a text pattern.
_i_kill_candidates() {
  printf '%-7s %-15s %-10s %s\n' \
    "100" "-"      "me"   "/opt/idea/bin/IntelliJ-idea --foo" \
    "101" ":8080"  "me"   "/opt/jetbrains/intellij/jbr/bin/java -Dx" \
    "102" "-"      "me"   "/usr/bin/INTELLIJ-helper" \
    "200" "-"      "idea" "bash" \
    "300" ":5432"  "pg"   "postgres -D /data"
}

KILLED=""
kill() { [[ "$1" == "-0" ]] && return 0; KILLED="${KILLED}${*:2} "; return 0; }

# Only the confirmation prompt (read -rp) is mocked; every other read falls through to the builtin.
_mock_answer() {
  _MOCK_ANSWER="$1"
  read() {
    if [[ "$1" == "-rp" ]]; then local -n _r="$3"; _r="${_MOCK_ANSWER}"; else builtin read "$@"; fi
  }
}

# Confirmation answered "y": exactly the three command lines containing intellij die.
_mock_answer y
KILLED=""
_i_kill_all_matching "intellij" >/dev/null
_expect_eq "all: kills every case-insensitive command-line match" "${KILLED}" "100 101 102 "

# "idea" appears in a USER column (pid 200) and in a command line (pid 100): only the latter counts.
KILLED=""
_i_kill_all_matching "idea" >/dev/null
_expect_eq "all: user column is not matched, only the command line" "${KILLED}" "100 "

# Answering anything but "y" kills nothing.
_mock_answer n
KILLED=""
_i_kill_all_matching "intellij" >/dev/null
_expect_eq "all: declined confirmation kills nothing" "${KILLED}" ""

# Default answer (empty) is also "no".
_mock_answer ""
KILLED=""
_i_kill_all_matching "intellij" >/dev/null
_expect_eq "all: empty answer defaults to no" "${KILLED}" ""

# No match / no pattern: no kill, and a missing pattern is an error.
_mock_answer y
KILLED=""
_i_kill_all_matching "nothing-like-this" >/dev/null
_expect_eq "all: no match kills nothing" "${KILLED}" ""
_i_kill_all_matching "" >/dev/null; rc=$?
_expect_eq "all: missing pattern returns an error" "${rc}" "1"

# Regex metacharacters are literal: "." must not act as a wildcard.
KILLED=""
_i_kill_all_matching "intellij.*java" >/dev/null
_expect_eq "all: pattern is literal, not a regex" "${KILLED}" ""

# Dispatch from the public command.
KILLED=""
_interactive_kill --all "postgres" >/dev/null
_expect_eq "all: reachable through _interactive_kill --all" "${KILLED}" "300 "

unset -f kill read _i_kill_candidates

#-----------------------------------------------------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------------------------------------------------
echo ""
echo "----------------------------------------"
echo "  Passed: ${PASS}   Failed: ${FAIL}"
echo "----------------------------------------"

[[ ${FAIL} -eq 0 ]] || exit 1
