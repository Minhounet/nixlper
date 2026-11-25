#!/usr/bin/env bash
# SessionStart: enable the repo's versioned git hooks (.githooks/commit-msg checks the gitmoji convention).
# Only when no hooks path is configured and .git/hooks holds nothing but samples, so a developer's own
# local hooks are never silently bypassed.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
[[ -n "$(git config --get core.hooksPath)" ]] && exit 0
hooks_dir="$(git rev-parse --git-path hooks)"
if [[ -d "${hooks_dir}" ]] && find "${hooks_dir}" -maxdepth 1 -type f ! -name '*.sample' | grep -q .; then
  exit 0
fi
git config core.hooksPath .githooks
exit 0
