#!/usr/bin/env bash
########################################################################################################################
# FILE: check-feature-completeness.sh
# DESCRIPTION: Mechanical checks for the "definition of done" rules in CLAUDE.md — the parts that are facts a
#              script can verify, so nobody (human or AI) has to remember them.
#
# Usage:
#   bash scripts/check-feature-completeness.sh                         # repo-state checks
#   bash scripts/check-feature-completeness.sh --changelog-base REF    # + CHANGELOG check for the branch vs REF
#   bash scripts/check-feature-completeness.sh --commit-msg FILE       # only validate a commit message (git hook)
#
# Repo-state checks:
#   1. every src/test/bash/test_*.sh is run by .github/workflows/tests.yml (CI does not auto-discover tests);
#   2. every variable in _NIXLPER_CONFIG_VARS (functions_config.sh) is present in the three config templates
#      (per-user _nconf_create_user_conf, install.sh --system _i_install_system, packaged
#      packaging/shared/nixlper.conf) and is mentioned in the English docs, the French docs and the in-shell help;
#   3. no template exports a NIXLPER_* variable unknown to _NIXLPER_CONFIG_VARS (catches typos and dead settings);
#   4. every docs/feature-*.md has a docs/fr/ twin, and the two link to each other.
#
# CHANGELOG check (--changelog-base): if the branch changes anything under src/main/ since its merge-base with REF,
# it must also change CHANGELOG.md. Escape hatch for pure refactors/tests: put [no-changelog] in any commit message
# of the branch. Skipped (with a note) when REF cannot be resolved, e.g. a shallow clone.
#
# Commit message format (--commit-msg): "<gitmoji><word>|Message." — see CLAUDE.md "Commits". Merge,
# revert and fixup!/squash! messages are accepted as-is. A trailing " (#123)" (GitHub squash merge) is allowed.
########################################################################################################################
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT
cd "${ROOT}" || exit 2

# Allowed commit-type words — the authoritative list for the commit convention (gitmoji word column).
readonly COMMIT_WORDS="style perf remove fix hotfix feat docs deploy ui init test security secrets release lint wip \
ci downgrade deps pin build-ci analytics refactor add-dep rm-dep config script i18n typo revert merge package api \
move license breaking assets a11y comment text db log no-log arch patch dead test-fail types seed flag catch \
deprecate auth explore validate thread"

errors=0
function _fail() { printf '❌ %s\n' "$*"; errors=$((errors + 1)); }

#***********************************************************************************************************************
# Commit message
#***********************************************************************************************************************
function check_commit_msg() {
  local -r file="$1"
  local subject
  subject="$(grep -v '^#' "${file}" | sed '/^[[:space:]]*$/d' | head -n 1)"
  [[ "${subject}" =~ ^(Merge|Revert|fixup!|squash!|amend!) ]] && return 0

  local -r re='^([^|[:alnum:][:space:]]+)([a-z0-9-]+)\|(.+)$'
  if [[ ! "${subject}" =~ ${re} ]]; then
    _fail "commit subject must look like '✨feat|Do something.' — got: ${subject}"
    return
  fi
  local -r word="${BASH_REMATCH[2]}" message="${BASH_REMATCH[3]}"
  if [[ " ${COMMIT_WORDS} " != *" ${word} "* ]]; then
    _fail "unknown commit type '${word}' (allowed: ${COMMIT_WORDS})"
  fi
  if [[ ! "${message}" =~ \.(\ \(#[0-9]+\))?$ ]]; then
    _fail "commit message must end with a period: ${subject}"
  fi
}

#***********************************************************************************************************************
# 1. Tests wired into CI
#***********************************************************************************************************************
function check_tests_in_ci() {
  local -r workflow=".github/workflows/tests.yml"
  local t
  for t in src/test/bash/test_*.sh; do
    [[ -f "${t}" ]] || continue
    grep -qF "${t}" "${workflow}" || _fail "${t} is not run by ${workflow} (add a named step)"
  done
}

#***********************************************************************************************************************
# 2 + 3. Config variables
#***********************************************************************************************************************
function _config_vars() {
  sed -n '/^_NIXLPER_CONFIG_VARS=(/,/^)/p' src/main/bash/functions_config.sh \
    | grep -oE '^[[:space:]]*"NIXLPER_[A-Z0-9_]+' | tr -d ' "'
}

function check_config_vars() {
  local user_tpl sys_tpl pkg_tpl
  user_tpl="$(sed -n '/^function _nconf_create_user_conf()/,/^}/p' src/main/bash/functions_config.sh)"
  sys_tpl="$(sed -n '/^function _i_install_system()/,/^}/p' src/main/bash/nixlper.sh)"
  pkg_tpl="$(cat packaging/shared/nixlper.conf)"

  local vars
  vars="$(_config_vars)"
  [[ -n "${vars}" ]] || { _fail "could not parse _NIXLPER_CONFIG_VARS"; return; }

  local v
  for v in ${vars}; do
    grep -qw "${v}" <<< "${user_tpl}" || _fail "${v}: missing from _nconf_create_user_conf (functions_config.sh)"
    grep -qw "${v}" <<< "${sys_tpl}"  || _fail "${v}: missing from _i_install_system template (nixlper.sh)"
    grep -qw "${v}" <<< "${pkg_tpl}"  || _fail "${v}: missing from packaging/shared/nixlper.conf"
    grep -qwsF "${v}" docs/*.md            || _fail "${v}: not documented in any docs/*.md page"
    grep -qwsF "${v}" docs/fr/*.md         || _fail "${v}: not documented in any docs/fr/*.md page"
    grep -qwsF "${v}" src/main/help/help_* || _fail "${v}: not documented in any src/main/help/help_* file"
  done

  # Reverse direction: anything a template exports must be a known setting.
  local name label tpl
  for label in user sys pkg; do
    case "${label}" in
      user) tpl="${user_tpl}" ;;
      sys)  tpl="${sys_tpl}" ;;
      pkg)  tpl="${pkg_tpl}" ;;
    esac
    while IFS= read -r name; do
      [[ -z "${name}" || "${name}" == "NIXLPER_INSTALL_DIR" ]] && continue
      grep -qx "${name}" <<< "${vars}" || _fail "${name}: exported by the ${label} template but not in _NIXLPER_CONFIG_VARS"
    done < <(grep -oE 'export NIXLPER_[A-Z0-9_]+' <<< "${tpl}" | sed 's/^export //' | sort -u)
  done
}

#***********************************************************************************************************************
# 4. English / French doc pairs
#***********************************************************************************************************************
function check_doc_pairs() {
  local f b
  for f in docs/feature-*.md; do
    b="$(basename "${f}")"
    if [[ ! -f "docs/fr/${b}" ]]; then
      _fail "docs/${b} has no French twin docs/fr/${b}"
      continue
    fi
    grep -qF "(fr/${b})" "${f}"           || _fail "docs/${b} does not link to fr/${b}"
    grep -qF "(../${b})" "docs/fr/${b}"   || _fail "docs/fr/${b} does not link back to ../${b}"
  done
  for f in docs/fr/feature-*.md; do
    b="$(basename "${f}")"
    [[ -f "docs/${b}" ]] || _fail "docs/fr/${b} has no English counterpart docs/${b}"
  done
}

#***********************************************************************************************************************
# CHANGELOG for the branch
#***********************************************************************************************************************
function check_changelog() {
  local -r ref="$1"
  local base
  if ! base="$(git merge-base HEAD "${ref}" 2>/dev/null)"; then
    printf 'ℹ️  changelog check skipped: cannot resolve merge-base with %s\n' "${ref}"
    return
  fi
  local changed
  changed="$(git diff --name-only "${base}" HEAD)"
  grep -q '^src/main/' <<< "${changed}" || return 0
  grep -qx 'CHANGELOG.md' <<< "${changed}" && return 0
  git log --format=%B "${base}..HEAD" | grep -qF '[no-changelog]' && return 0
  _fail "branch changes src/main/ but not CHANGELOG.md — add an [Unreleased] bullet, or put [no-changelog] in a commit message for a pure refactor/test change"
}

#***********************************************************************************************************************
# Main
#***********************************************************************************************************************
changelog_ref=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit-msg)
      [[ -f "${2:-}" ]] || { echo "usage: $0 --commit-msg FILE" >&2; exit 2; }
      check_commit_msg "$2"
      exit $(( errors > 0 ))
      ;;
    --changelog-base)
      changelog_ref="${2:-}"; shift 2 ;;
    *)
      echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

check_tests_in_ci
check_config_vars
check_doc_pairs
[[ -n "${changelog_ref}" ]] && check_changelog "${changelog_ref}"

if (( errors > 0 )); then
  printf '\n%d problem(s) found — see "Definition of done" in CLAUDE.md.\n' "${errors}"
  exit 1
fi
echo "✅ feature-completeness: tests wired, config templates and docs in sync"
