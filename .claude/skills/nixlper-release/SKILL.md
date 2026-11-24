---
name: nixlper-release
description: Cut a nixlper release (e.g. "make a release vX.Y.Z") — version bump rules, CHANGELOG/README updates, "Turnabout" codenames for majors, the direct-to-main release commit that triggers CI publishing, and how the scheduled automated release works. Load for anything touching releases, tags, CHANGELOG version blocks or scripts/prepare-release.sh.
---

# Releasing nixlper

## How a release happens
Release commits go **directly to `main`** — no feature branch, no PR (mobile-friendly). Pushing a commit whose
message starts with `🔖release|Release v` triggers `.github/workflows/create_release_on_tag.yml`, which creates the
tag, builds tar/RPM/DEB plus the PowerShell zip, extracts the CHANGELOG entry and publishes the GitHub release.
No manual tag push or GitHub UI step. The build reads the tag via `git describe --tags --exact-match HEAD`.

Two paths:
- **On demand** — the user says "make a release vX.Y.Z"; follow the steps below.
- **Automatic** — `.github/workflows/scheduled_release.yml` (Friday cron + `workflow_dispatch`) runs
  `scripts/prepare-release.sh`. See "Automated releases".

## Choosing the version
- **PATCH** `X.Y.Z+1` — fixes only.
- **MINOR** `X.Y+1.0` — new backward-compatible features.
- **MAJOR** `X+1.0.0` — breaking changes or a real paradigm shift. Needs a codename (below).

## Steps (on demand)
1. `git checkout main && git pull origin main`.
2. **CHANGELOG.md** ([Keep a Changelog](https://keepachangelog.com/en/1.0.0/)): move the `[Unreleased]` bullets into
   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD

   ### Added
   ### Fixed
   ### Changed
   ### Removed
   ```
   dropping empty sections, and leave `## [Unreleased]` empty. If `[Unreleased]` is incomplete, fill the gaps from
   `git log --pretty=format:"%ad %s" --date=short vPREV..HEAD`, grouped and written in plain English; skip pure
   doc/CI/build commits unless users notice them.
3. **README.md** opening block — bump the version and rewrite the one-sentence "What's new" from the new entry:
   ```markdown
   > 🚀 **Current version: vX.Y.Z** — [Release notes](https://github.com/Minhounet/nixlper/releases)
   >
   > **What's new in vX.Y.Z:** One-sentence summary.
   ```
4. Commit and push:
   ```bash
   git commit -am "🔖release|Release vX.Y.Z."
   git push -u origin main
   ```
5. No PR exists, so wait for the usual workflow runtime, then check `mcp__github__actions_list` once for both
   `Tests` and the release workflow. On failure, read the logs (`mcp__github__get_job_logs`, `failed_only: true`),
   fix, push again.

## Codenames (major releases only)
`## [X.0.0] "Turnabout <Word>" - YYYY-MM-DD` — Ace Attorney case-title pattern with JRPG weight in `<Word>`.
v2.0.0 is **"Turnabout Genesis"** (command palette + proper packaging). Brainstorm a fresh word that fits the release
(spirit: Ascension, Nexus, Requiem, Zenith, Vanguard, Reckoning…) and let the user pick. Minor/patch stay unnamed.

## Automated releases
`scripts/prepare-release.sh` is plain bash — no LLM, no API key, no cost beyond Actions minutes:
1. Reads `[Unreleased]`; no bullets → exit 0 (most weeks nothing happens).
2. Bump: any commit since the last tag starting with `💥` → MAJOR; else non-empty `### Added` → MINOR; else PATCH.
3. Promotes the bullets into a dated block, drops empty sections, resets `[Unreleased]`.
4. Updates the README badge and "What's new" by joining the bullets' **bold lead-ins** (`build_summary`) — so write
   CHANGELOG bullets with a bold lead-in.

MAJOR is never pushed to `main`: the script commits to `release/vX.0.0-draft` and exits with a distinct status; the
workflow opens a PR and a human picks the codename and merges. The workflow refuses to release unless `tests.yml`
succeeded on the current `main` HEAD.

Setup (one-time, repo admin): a `RELEASE_PAT` secret (classic `repo` scope, or fine-grained Contents + Pull requests
read/write). `GITHUB_TOKEN` can't be used — pushes made with it don't trigger other workflows, so the release
workflow would never fire. An earlier version called the Claude API for the summary; it was removed because the
project has no API billing — the pipeline is deterministic end to end.

Preview: run the workflow with `dry_run: true`, or `DRY_RUN=1 bash scripts/prepare-release.sh` locally.
