# Nixlper — Project Context

Nixlper is a bash helper inspired by Total Commander: keyboard-driven navigation, bookmarks, macros, process
management and more, exposed as aliases (`fa`, `ik`, `rd`…) and `CTRL+X` key chords. Commands are discovered from
`# @cmd-palette` annotations. Philosophy: keyboard first, modular sources / single distributed file, several install
methods (tar, RPM, DEB), safety first. A PowerShell port lives alongside it (preview).

This file holds only what applies to **every** task. Task-specific procedures live in skills — load the matching one
before starting:

| Skill | Load when… |
|---|---|
| `nixlper-add-feature` | adding/changing a command, alias, keybinding, setting or module (`src/main/bash`, help, docs) |
| `nixlper-release` | the user asks for a release, or you touch CHANGELOG version blocks / `prepare-release.sh` |
| `nixlper-packaging` | touching `build*.sh`, `install.sh`, `packaging/`, install/update code, config loading order |
| `nixlper-powershell` | touching anything under `src/main/powershell` or `build-ps.sh` |

Reference files (read on demand, keep current):
- [`MODULES.md`](MODULES.md) — per-module design notes. Read the module's entry before changing it.
- [`INTERNALS.md`](INTERNALS.md) — mechanisms behind non-obvious features (`bind -x`, `PROMPT_COMMAND`, state files…).
- [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) — confirmed, unfixed bugs. Check it before working on navigation/file commands;
  remove an entry in the commit that fixes it.

## Layout

```
src/main/bash/nixlper.sh        entry point: install/update/uninstall, _i_init, _i_load_bindings
src/main/bash/functions_*.sh    feature modules (build.sh concatenates them into one nixlper.sh)
src/main/help/help_<category>   in-shell help (CTRL+X+H)
src/main/powershell/Nixlper/    PowerShell port
src/test/bash/test_functions_*.sh, src/test/powershell/Test-Nixlper.ps1
docs/feature-*.md, docs/fr/feature-*.md   GitHub Pages (EN / FR)
packaging/                      RPM spec, shared system conf + profile.d loader
scripts/                        check-doc-sync.sh, check-feature-completeness.sh, prepare-release.sh
.claude/                        settings + hooks + skills; .githooks/ holds the commit-msg hook
```

## Always-on rules

- **Naming**: `snake_case` functions, `_` prefix for internals (`_i_…` for init/infra), `NIXLPER_*` settings.
- **Safety**: `rm -i`, confirmation prompts, show a command before executing it.
- **Settings** are declared once in `_NIXLPER_CONFIG_VARS` (`functions_config.sh`) — the source of truth for names
  and defaults — and read as `${NIXLPER_X:-default}`. Anything that can reasonably vary per user should be a setting.
- **Docs**: every command/alias/keybinding appears in the help file and in the EN **and** FR Pages docs, in the same
  commit as the code ("tri-location rule", details in `nixlper-add-feature`). `README.md → ## Features` stays a brief
  overview — no command details there.
- **Records**: every fix/feature gets a `CHANGELOG.md` `[Unreleased]` bullet; keep `KNOWN_ISSUES.md`, `INTERNALS.md`,
  `MODULES.md` and this file current when a change affects them.
- **Test** every change before committing: source the module in a subshell and exercise the new case, a regression
  case and an edge case. If something can't be tested here, tell the user before committing.

## Definition of done

Checked by scripts (CI `tests.yml` and the pre-commit hook — a failing check **blocks** `git commit`):
- `bash scripts/check-doc-sync.sh` — each palette command's alias/keybind is in its help, EN and FR files.
- `bash scripts/check-feature-completeness.sh --changelog-base origin/main` — unit tests wired into `tests.yml`;
  every setting in all three config templates and the docs; EN/FR page pairs linked; branch touching `src/main/`
  also touches `CHANGELOG.md` (escape hatch: `[no-changelog]` in a commit message for pure refactor/test work).

Your judgment (no script can do this):
- **Bug sweep** of every function you wrote or touched: special characters, missing files, running twice, older
  callers whose assumptions changed. Fix, or log in `KNOWN_ISSUES.md`. For a larger change, run `/code-review`.
- The help/EN/FR **prose** really describes the new behaviour (the scripts only check that names are present).
- New/changed palette commands render correctly (snippet in `nixlper-add-feature`).

## Commits

Format `<gitmoji><word>|Imperative message ending with a period.` — e.g. `✨feat|Add fuzzy search for bookmarks.`,
`🐛fix|Resolve null expansion in nixlper.sh.`, `📝docs|…`, `♻️refactor|…`, `✅test|…`, `🔧config|…`, `🔨script|…`,
`🔖release|Release vX.Y.Z.`, `💥breaking|…` (💥 makes the next automated release a MAJOR). Use the emoji character,
not `:code:`. The allowed words are listed in `scripts/check-feature-completeness.sh` (`COMMIT_WORDS`, from the
[gitmoji list](https://raw.githubusercontent.com/carloscuesta/gitmoji/master/packages/gitmojis/src/gitmojis.json));
`.githooks/commit-msg` enforces the format (enabled automatically in Claude sessions).

## Workflow

1. Before coding, show the user a short plan and agree on the approach.
2. Work on a feature branch. Exceptions that go **straight to `main`**: release commits (see `nixlper-release`) and
   joke additions to `_NIXLPER_JOKES_FR`/`_NIXLPER_JOKES_EN` in `functions_jokes.sh`
   (`💬text|Add <FR/EN> joke to bundled list.` — nothing else to update).
3. Before committing: `bash build.sh`, run the affected tests, then commit.
4. **After every push, verify CI.** With an open PR: call `subscribe_pr_activity` once and react to the events (fix
   and push on failure, report done when green). Without a PR (pushes to `main`): wait roughly the workflow's
   runtime, check `mcp__github__actions_list` once; on failure read `mcp__github__get_job_logs`
   (`failed_only: true`), fix, push, re-check. Never hand back with red CI — if the fix is out of scope, explain the
   failure and the options.

## Feature backlog

Agreed but not implemented — pick these up in future sessions:
- **Environment snapshot diff**: compare `env`/`PATH`/loaded modules between two points in time — useful when a
  script breaks something and you need to know what changed.

## Keeping this file current

Add something here only if **every** future task needs it. Procedures go in a skill under `.claude/skills/`,
module notes in `MODULES.md`, mechanisms in `INTERNALS.md`. If a rule can be checked mechanically, add it to
`scripts/check-feature-completeness.sh` instead of writing it down.
