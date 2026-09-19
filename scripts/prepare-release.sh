#!/usr/bin/env bash
# Promotes CHANGELOG.md's [Unreleased] section into a versioned release block,
# updates the README badge, and commits with the exact "🔖release|Release
# vX.Y.Z." message that .github/workflows/create_release_on_tag.yml watches
# for on push to main. Meant to be run by .github/workflows/scheduled_release.yml,
# but is a plain script so it can also be run by hand.
#
# Version bump rule (mirrors CLAUDE.md's "Release process" policy):
#   - any commit since the last tag starts with the 💥 (breaking) gitmoji -> MAJOR
#   - else [Unreleased] has a non-empty "### Added" section               -> MINOR
#   - else (only Fixed/Changed/Removed)                                  -> PATCH
#
# MAJOR bumps are never pushed to main directly: CLAUDE.md requires a
# human-picked "Turnabout <Word>" codename for major releases, so this script
# commits the draft to a release/vX.0.0-draft branch, pushes it, and exits 20
# so the caller opens a PR instead.
#
# Exit codes:
#   0  - nothing under [Unreleased] to release, or DRY_RUN produced a preview
#   10 - release commit created on the current branch, ready to push to main
#   20 - MAJOR bump: draft branch pushed, caller should open a PR
#   1  - error (bad state, missing previous tag, etc.)
#
# Pure bash, no external dependencies and no LLM calls of any kind — the
# README "What's new" sentence is built from the changelog bullets' bold
# lead-ins, not generated.
#
# Env:
#   DRY_RUN=1  compute and print the plan; write no files, commit nothing.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CHANGELOG="CHANGELOG.md"
README="README.md"
DRY_RUN="${DRY_RUN:-0}"

git config user.email >/dev/null 2>&1 || git config user.email "actions@github.com"
git config user.name  >/dev/null 2>&1 || git config user.name  "nixlper-release-bot"

# --- 1. Extract the [Unreleased] block -----------------------------------
unreleased_block="$(awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' "$CHANGELOG")"

if ! grep -q '^- ' <<<"$unreleased_block"; then
  echo "Nothing under [Unreleased] with actual bullets — nothing to release."
  exit 0
fi

# --- 2. Split into sections, dropping any with no bullets -----------------
declare -A section_lines=()
current_section=""
while IFS= read -r line; do
  if [[ "$line" =~ ^###[[:space:]]+(.+)$ ]]; then
    current_section="${BASH_REMATCH[1]}"
    : "${section_lines[$current_section]:=}"
  elif [[ -n "$current_section" && "$line" == -\ * ]]; then
    section_lines["$current_section"]+="${line}"$'\n'
  fi
done <<<"$unreleased_block"

# --- 3. Determine the version bump -----------------------------------------
last_tag="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
if [[ -z "$last_tag" ]]; then
  echo "No previous vX.Y.Z tag found — refusing to guess the first release version." >&2
  exit 1
fi
IFS='.' read -r cur_major cur_minor cur_patch <<<"${last_tag#v}"

breaking=0
if git log --pretty=%s "${last_tag}..HEAD" | grep -qE '^💥'; then
  breaking=1
fi

if [[ "$breaking" -eq 1 ]]; then
  bump="major"
  new_version="$((cur_major + 1)).0.0"
elif [[ -n "${section_lines[Added]:-}" ]]; then
  bump="minor"
  new_version="${cur_major}.$((cur_minor + 1)).0"
else
  bump="patch"
  new_version="${cur_major}.${cur_minor}.$((cur_patch + 1))"
fi

echo "Bump: ${bump} -> v${new_version} (previous: ${last_tag})"

# --- 4. Build the filtered section body (empty sections dropped) ----------
filtered_body="$(
  for name in Added Fixed Changed Removed; do
    if [[ -n "${section_lines[$name]:-}" ]]; then
      printf '### %s\n\n%s\n' "$name" "${section_lines[$name]}"
    fi
  done
)"

today="$(date -u +%F)"

# --- 5. Rewrite CHANGELOG.md: reset [Unreleased], insert the new block ----
# `body` goes through ENVIRON rather than -v: awk's -v assignment applies
# string-escape processing (POSIX), so a changelog bullet containing "\n",
# "\t", or similar would be silently corrupted. ENVIRON values are verbatim.
export AWK_BODY="$filtered_body"
new_changelog="$(awk -v newver="$new_version" -v today="$today" '
  BEGIN { skipping = 0; body = ENVIRON["AWK_BODY"] }
  /^## \[Unreleased\]$/ {
    print "## [Unreleased]"
    print ""
    print "## [" newver "] - " today
    print ""
    # $(...) in bash strips all trailing newlines from `body`, so re-add
    # exactly one blank line here before the block'"'"'s original trailing "---".
    printf "%s\n\n", body
    skipping = 1
    next
  }
  skipping && /^---$/ {
    skipping = 0
    print
    next
  }
  skipping { next }
  { print }
' "$CHANGELOG")"

# --- 6. Build the README "What's new" summary -----------------------------
# Templated, not generated: joins the changelog bullets' bold lead-ins.
build_summary() {
  local body="$1" leads
  leads="$(grep -oE '\*\*[^*]+\*\*' <<<"$body" | sed -E 's/\*\*//g' | head -3 | paste -sd, - | sed -E 's/,/, /g')"
  printf 'Adds/updates: %s.' "${leads:-see CHANGELOG for details}"
}

summary="$(build_summary "$filtered_body")"

# --- 7. Rewrite README.md: badge version + "What's new" line --------------
update_readme() {
  local new_version="$1" summary="$2"
  local whats_new_pattern="^> \*\*What's new in v[0-9]+\.[0-9]+\.[0-9]+:\*\*"
  local tmp replaced=0
  tmp="$(mktemp)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $whats_new_pattern ]]; then
      printf "> **What's new in v%s:** %s\n" "$new_version" "$summary" >>"$tmp"
      replaced=1
    else
      printf '%s\n' "$line" >>"$tmp"
    fi
  done <"$README"
  if [[ "$replaced" -eq 0 ]]; then
    echo "warning: could not find README \"What's new\" line to update" >&2
  fi
  mv "$tmp" "$README"
  sed -i -E "s/Current version: v[0-9]+\.[0-9]+\.[0-9]+/Current version: v${new_version}/" "$README"
}

# --- 8. Dry run: print the plan and stop -----------------------------------
if [[ "$DRY_RUN" == "1" ]]; then
  echo "---- DRY RUN: CHANGELOG.md would become ----"
  diff -u "$CHANGELOG" <(printf '%s\n' "$new_changelog") || true
  echo "---- DRY RUN: README summary would be ----"
  echo "v${new_version}: ${summary}"
  exit 0
fi

# --- 9. Write files, commit -------------------------------------------------
printf '%s\n' "$new_changelog" >"$CHANGELOG"
update_readme "$new_version" "$summary"

git add "$CHANGELOG" "$README"

if [[ "$bump" == "major" ]]; then
  branch="release/v${new_version}-draft"
  git checkout -b "$branch"
  git commit -m "🔖release|Prepare v${new_version} (draft, needs codename)."
  git push -u origin "$branch"
  echo "MAJOR bump drafted on ${branch} — open a PR and pick a codename before merging to main."
  exit 20
fi

git commit -m "🔖release|Release v${new_version}."
echo "Release commit ready on $(git branch --show-current). Push it to main to trigger the release."
exit 10
