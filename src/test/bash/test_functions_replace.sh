#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_replace.sh
# DESCRIPTION: Offline unit tests for the interactive search & replace command `rp` (functions_files_and_folders.sh).
#
# Pure bash, no external framework. The interactive prompts are fed through stdin. The confirm-each mode (flag c)
# needs a real terminal and is not exercised here.
# Run locally with:  bash src/test/bash/test_functions_replace.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_files_and_folders.sh"
LOGGING="${REPO_ROOT}/src/main/bash/functions_logging.sh"

# shellcheck source=/dev/null
source "${LOGGING}"
# shellcheck source=/dev/null
source "${MODULE}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
export NIXLPER_SNAPSHOT_DIR="${WORK_DIR}/snapshots"
export NIXLPER_INSTALL_DIR="${WORK_DIR}/install"
unset NIXLPER_REPLACE_SNAPSHOT

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
_expect_contains() {
  local -r name="$1" haystack="$2" needle="$3"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    echo "  ✅ ${name}"; PASS=$((PASS + 1))
  else
    echo "  ❌ ${name}: [${needle}] not found in [${haystack}]"; FAIL=$((FAIL + 1))
  fi
}

# rp_run FILE ANSWERS... : feed one answer per prompt (search, replace, lines, flags, apply, ...)
rp_run() {
  local -r file="$1"; shift
  printf '%s\n' "$@" | _replace_in_file "${file}" 2>&1
}

new_file() { printf '%s\n' "timeout=30" "name=foo" "retry_timeout=30" > "${WORK_DIR}/f.conf"; echo "${WORK_DIR}/f.conf"; }

if ! command -v ex > /dev/null 2>&1; then
  echo "❌ ex (vim) is required to run these tests" >&2
  exit 1
fi

echo "== helpers =="
_expect_eq "delimiter: / by default" "$(_i_replace_pick_delimiter a b)" "/"
_expect_eq "delimiter: skips / when used in a path" "$(_i_replace_pick_delimiter /etc/a b)" "#"
_expect_eq "delimiter: skips every used char" "$(_i_replace_pick_delimiter '/#' '@')" "!"
_i_replace_has_bare_pipe 'a|b' && r=bare || r=ok;  _expect_eq "bare pipe detected" "${r}" "bare"
_i_replace_has_bare_pipe 'a\|b' && r=bare || r=ok; _expect_eq "escaped pipe accepted" "${r}" "ok"
_i_replace_has_bare_pipe 'a\\|b' && r=bare || r=ok; _expect_eq "escaped backslash then pipe is bare" "${r}" "bare"

echo "== usage / error cases =="
out="$(_replace_in_file 2>&1)"; rc=$?
_expect_contains "no argument: usage" "${out}" "Usage: rp FILENAME"; _expect_eq "no argument: rc 1" "${rc}" "1"
out="$(_replace_in_file "${WORK_DIR}/nope" 2>&1)"; rc=$?
_expect_contains "missing file: error" "${out}" "File not found"; _expect_eq "missing file: rc 1" "${rc}" "1"
head -c 64 /dev/urandom > "${WORK_DIR}/bin.dat"; printf '\0\1\2binary' >> "${WORK_DIR}/bin.dat"
out="$(rp_run "${WORK_DIR}/bin.dat" a b)"
_expect_contains "binary file refused" "${out}" "Binary file"

printf '\n\n' > "${WORK_DIR}/blank.txt"
out="$(rp_run "${WORK_DIR}/blank.txt" a b)"
if [[ "${out}" == *"Binary file"* ]]; then r=refused; else r=accepted; fi
_expect_eq "file with only blank lines is not mistaken for binary" "${r}" "accepted"

echo "== basic replace (apply) =="
f="$(new_file)"
out="$(rp_run "$f" '^timeout=30' 'timeout=60' '' '' y)"
_expect_contains "preview shows removed line" "${out}" "   1 - timeout=30"
_expect_contains "preview shows added line" "${out}" "   1 + timeout=60"
_expect_contains "reports changed lines" "${out}" "1 line(s) would change"
_expect_eq "file updated, other lines untouched" "$(cat "$f")" "$(printf '%s\n' timeout=60 name=foo retry_timeout=30)"
snap="${NIXLPER_SNAPSHOT_DIR}$(realpath "$f")"
_expect_eq "snapshot holds the original" "$(head -1 "${snap}")" "timeout=30"

echo "== decline leaves file untouched =="
f="$(new_file)"
out="$(rp_run "$f" 'foo' 'bar' '' '' n)"
_expect_eq "file unchanged when answering n" "$(sed -n 2p "$f")" "name=foo"
_expect_contains "cancel message" "${out}" "cancelled"

echo "== default flag g replaces every match on a line =="
printf 'a a a\n' > "${WORK_DIR}/g.txt"
rp_run "${WORK_DIR}/g.txt" a b '' '' y > /dev/null
_expect_eq "g by default" "$(cat "${WORK_DIR}/g.txt")" "b b b"
printf 'a a a\n' > "${WORK_DIR}/g.txt"
printf 'a a a\n' > "${WORK_DIR}/g.txt"
rp_run "${WORK_DIR}/g.txt" a b '' 'i' y > /dev/null
_expect_eq "no g: first match only" "$(cat "${WORK_DIR}/g.txt")" "b a a"

echo "== line range =="
f="$(new_file)"
rp_run "$f" 'timeout' 'T' '3' 'g' y > /dev/null
_expect_eq "range 3 only touches line 3" "$(cat "$f")" "$(printf '%s\n' timeout=30 name=foo retry_T=30)"
f="$(new_file)"
rp_run "$f" 'o' '0' '/name/,$' 'g' y > /dev/null
_expect_eq "pattern range" "$(sed -n 1p "$f")|$(sed -n 2p "$f")" "timeout=30|name=f00"

echo "== vi regex features =="
f="$(new_file)"
rp_run "$f" '^\(\w\+\)=30' '\1=99' '' '' y > /dev/null
_expect_eq "groups and \\1" "$(sed -n 1p "$f")" "timeout=99"
f="$(new_file)"
rp_run "$f" 'name' '[&]' '' '' y > /dev/null
_expect_eq "& is the whole match" "$(sed -n 2p "$f")" "[name]=foo"

echo "== slash in search/replacement needs no escaping =="
printf 'path=/usr/bin\n' > "${WORK_DIR}/p.txt"
rp_run "${WORK_DIR}/p.txt" '/usr/bin' '/opt/bin' '' '' y > /dev/null
_expect_eq "paths replaced" "$(cat "${WORK_DIR}/p.txt")" "path=/opt/bin"

echo "== special characters =="
printf 'a.b a-b\n' > "${WORK_DIR}/s.txt"
rp_run "${WORK_DIR}/s.txt" 'a\.b' 'X' '' '' y > /dev/null
_expect_eq "escaped dot is literal" "$(cat "${WORK_DIR}/s.txt")" "X a-b"
printf 'x\n' > "${WORK_DIR}/s.txt"
rp_run "${WORK_DIR}/s.txt" 'x' 'a\|b' '' '' y > /dev/null
_expect_eq "escaped pipe in replacement is literal" "$(cat "${WORK_DIR}/s.txt")" "a|b"
printf 'x\n' > "${WORK_DIR}/s.txt"
out="$(rp_run "${WORK_DIR}/s.txt" 'x' 'a|!touch '"${WORK_DIR}"'/pwned' '' '' y)"
_expect_contains "bare pipe in replacement rejected" "${out}" "Bare '|'"
[[ -e "${WORK_DIR}/pwned" ]] && r=injected || r=safe
_expect_eq "no ex command injection" "${r}" "safe"

echo "== no match / identical =="
f="$(new_file)"
before="$(cat "$f")"
out="$(rp_run "$f" 'zzz' 'y' '' '')"
_expect_contains "no match message" "${out}" "No change"
_expect_eq "file unchanged on no match" "$(cat "$f")" "${before}"

echo "== invalid input =="
out="$(rp_run "$(new_file)" 'a' 'b' '' 'xyz')"
_expect_contains "invalid flags rejected" "${out}" "Invalid flags"
out="$(rp_run "$(new_file)" '' )"
_expect_contains "empty search cancels" "${out}" "cancelled"

echo "== file properties =="
printf 'no newline at end' > "${WORK_DIR}/n.txt"; chmod 640 "${WORK_DIR}/n.txt"
rp_run "${WORK_DIR}/n.txt" 'end' 'END' '' '' y > /dev/null
_expect_eq "missing final newline preserved" "$(tail -c1 "${WORK_DIR}/n.txt")" "D"
_expect_eq "content" "$(cat "${WORK_DIR}/n.txt")" "no newline at END"
_expect_eq "permissions preserved" "$(stat -c %a "${WORK_DIR}/n.txt")" "640"

echo "== snapshot disabled =="
f="$(new_file)"; rm -rf "${NIXLPER_SNAPSHOT_DIR}"
NIXLPER_REPLACE_SNAPSHOT=false rp_run "$f" 'foo' 'bar' '' '' y > /dev/null
[[ -e "${NIXLPER_SNAPSHOT_DIR}$(realpath "$f")" ]] && r=created || r=none
_expect_eq "no snapshot when disabled" "${r}" "none"

echo "== existing snapshot not overwritten without consent =="
f="$(new_file)"; rm -rf "${NIXLPER_SNAPSHOT_DIR}"
mkdir -p "$(dirname "${NIXLPER_SNAPSHOT_DIR}$(realpath "$f")")"; echo "OLD" > "${NIXLPER_SNAPSHOT_DIR}$(realpath "$f")"
rp_run "$f" 'foo' 'bar' '' '' y n > /dev/null
_expect_eq "older snapshot kept" "$(cat "${NIXLPER_SNAPSHOT_DIR}$(realpath "$f")")" "OLD"
_expect_eq "edit still applied" "$(sed -n 2p "$f")" "name=bar"

echo "== alias registration (regression) =="
_expect_eq "alias rp wired in nixlper.sh" "$(grep -c '^alias rp=_replace_in_file$' "${REPO_ROOT}/src/main/bash/nixlper.sh")" "1"

echo ""
echo "RESULT: ${PASS} passed, ${FAIL} failed"
[[ ${FAIL} -eq 0 ]]
