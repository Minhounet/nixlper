#!/usr/bin/env bash
########################################################################################################################
# FILE: test_functions_jokes.sh
# DESCRIPTION: Offline unit tests for the jokes feature (functions_jokes.sh).
#
# Pure bash, no external framework. Run locally with:
#   bash src/test/bash/test_functions_jokes.sh
########################################################################################################################
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE="${REPO_ROOT}/src/main/bash/functions_jokes.sh"

if [[ ! -f "${MODULE}" ]]; then
  echo "❌ Cannot find module under test: ${MODULE}" >&2
  exit 1
fi

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
    echo "  ❌ ${name}: [${needle}] not found in output"
    FAIL=$((FAIL + 1))
  fi
}

#-----------------------------------------------------------------------------------------------------------------------
echo "── _i_joke_lang ──────────────────────────────────────────────────────────────"
#-----------------------------------------------------------------------------------------------------------------------

# Note: inline assignment (VAR=x cmd "$(subshell)") does NOT apply to the subshell
# expansion — use explicit export/unset around each call instead.

unset NIXLPER_JOKE_LANG

LANG=fr_FR.UTF-8; result=$(_i_joke_lang)
_expect_eq "auto + fr_FR.UTF-8 locale → fr" "${result}" "fr"

LANG=fr_FR; result=$(_i_joke_lang)
_expect_eq "auto + fr_FR → fr" "${result}" "fr"

LANG=en_US.UTF-8; result=$(_i_joke_lang)
_expect_eq "auto + en locale → en" "${result}" "en"

LANG=de_DE.UTF-8; result=$(_i_joke_lang)
_expect_eq "auto + de locale → en" "${result}" "en"

LANG=""; result=$(_i_joke_lang)
_expect_eq "auto + empty LANG → en" "${result}" "en"

NIXLPER_JOKE_LANG=fr; LANG=en_US.UTF-8; result=$(_i_joke_lang)
_expect_eq "forced fr overrides en locale" "${result}" "fr"

NIXLPER_JOKE_LANG=en; LANG=fr_FR.UTF-8; result=$(_i_joke_lang)
_expect_eq "forced en overrides fr locale" "${result}" "en"

NIXLPER_JOKE_LANG=auto; LANG=fr_FR.UTF-8; result=$(_i_joke_lang)
_expect_eq "explicit auto + fr locale → fr" "${result}" "fr"

unset NIXLPER_JOKE_LANG
LANG=en_US.UTF-8

#-----------------------------------------------------------------------------------------------------------------------
echo "── show_joke output ──────────────────────────────────────────────────────────"
#-----------------------------------------------------------------------------------------------------------------------

LANG=en_US.UTF-8; output=$(show_joke)
_expect_contains "EN output has box top border"    "${output}" "╭"
_expect_contains "EN output has box bottom border" "${output}" "╰"
_expect_contains "EN output has joke label"        "${output}" "Nixlper joke"

LANG=fr_FR.UTF-8; output=$(show_joke)
_expect_contains "FR output has box top border"    "${output}" "╭"
_expect_contains "FR output has box bottom border" "${output}" "╰"

NIXLPER_JOKE_LANG=fr; output=$(show_joke)
is_french=0
for joke in "${_NIXLPER_JOKES_FR[@]}"; do
  [[ "${output}" == *"${joke}"* ]] && is_french=1 && break
done
_expect_eq "forced FR → joke is from French list" "${is_french}" "1"

NIXLPER_JOKE_LANG=en; output=$(show_joke)
is_english=0
for joke in "${_NIXLPER_JOKES_EN[@]}"; do
  [[ "${output}" == *"${joke}"* ]] && is_english=1 && break
done
_expect_eq "forced EN → joke is from English list" "${is_english}" "1"

unset NIXLPER_JOKE_LANG

#-----------------------------------------------------------------------------------------------------------------------
echo "── joke arrays are non-empty ─────────────────────────────────────────────────"
#-----------------------------------------------------------------------------------------------------------------------

_expect_eq "FR joke list is non-empty" "$([[ ${#_NIXLPER_JOKES_FR[@]} -gt 0 ]] && echo ok || echo empty)" "ok"
_expect_eq "EN joke list is non-empty" "$([[ ${#_NIXLPER_JOKES_EN[@]} -gt 0 ]] && echo ok || echo empty)" "ok"

#-----------------------------------------------------------------------------------------------------------------------
echo "─────────────────────────────────────────────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
