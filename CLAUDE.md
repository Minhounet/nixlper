# Nixlper - Project Context

## Meta — Keeping This File Current

Update this file whenever a session introduces something a future session would need to know:
new files or directories, architectural decisions, new env variables, build steps, or constraints
discovered during implementation. The goal is that any new session can start from this file
without re-discovering context.

## Known Issues

Confirmed-but-unfixed defects are tracked in [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md). Consult it
before working on navigation/file commands, and keep it in sync: remove an entry in the same
commit that fixes the underlying bug.

---

## ⚠️ MANDATORY: Documentation Completeness — NEVER SKIP

**After every code change, you MUST update ALL of the following that are affected. This is not optional and must never be skipped, even for "small" changes.**

### Checklist — run through this after every task

1. **`src/main/help/help_<category>`** — in-shell help (CTRL+X+H). Update if any command behaviour, alias, keybinding, or output format changed.
2. **`docs/feature-*.md` and **`docs/fr/feature-*.md`** (GitHub Pages — English & French)** — user-facing command reference. Both language versions must stay in sync with the help files and with each other (see "Tri-location documentation rule"). Update all affected pages in the same commit as the code. `README.md → ## Features` is intentionally a brief overview with a link to the Pages site — do not add command details there.
3. **`CLAUDE.md`** — update if the session introduces new files, directories, env variables, architectural decisions, or constraints.
4. **`KNOWN_ISSUES.md`** — remove an entry in the same commit that fixes the underlying bug. Add an entry for newly discovered confirmed-but-unfixed defects.
5. **`CHANGELOG.md`** — after every bug fix or feature, add a bullet to the `[Unreleased]` section under the appropriate heading (`Added`, `Fixed`, `Changed`, or `Removed`). When cutting a release, promote the `[Unreleased]` entries into a versioned block and clear the section (see "Release process").
6. **Palette rendering** — if any `@cmd-palette` command was added or modified, verify it renders correctly (see "Command palette rendering check" under Testing requirement). A command with no `@keybind` or `@alias` may have a blank keybind column — that is acceptable. What is **never acceptable** is a command that *has* a keybind or alias defined but it does not appear in the palette column.
7. **`INTERNALS.md`** — update if a feature's mechanism changes in a non-obvious way (see "INTERNALS.md rule" below).

### Tri-location documentation rule (enforced)

Every command, alias, and keybinding **must** appear in all three locations:
- the corresponding `src/main/help/help_<category>` file (in-shell help), and
- the corresponding `docs/feature-*.md` page (GitHub Pages — English), and
- the corresponding `docs/fr/feature-*.md` page (GitHub Pages — French).

After any feature work, compare all three locations and flag any discrepancy — do not close the task until they are in sync. `README.md → ## Features` is a summary table that links to the Pages site; it does **not** need to list every command.

**French pages live in `docs/fr/`.** Each French page links back to its English counterpart with `> 🇬🇧 [English version](../feature-name.md)`, and each English page links to its French counterpart with `> 🇫🇷 [Version française](fr/feature-name.md)`.

> **Root cause of doc drift:** code is changed but only one location (or neither) is updated. The checklist above exists to prevent this. If you find yourself thinking "I'll update the docs later" — stop and update them now, in the same commit.

### INTERNALS.md rule

[`INTERNALS.md`](INTERNALS.md) explains the **mechanism** behind features that are non-obvious from reading the code. It is aimed at any future developer (human or AI) who asks "how does this actually work?"

**Add or update an `INTERNALS.md` entry when the feature being changed meets at least one of these criteria:**

1. **Non-obvious shell mechanism** — uses `PROMPT_COMMAND`, `bind -x`, history builtins, `trap`, or other bash internals whose behavior is not self-evident.
2. **Persistent state across calls** — maintains counters, arrays, or file-backed state that affect subsequent invocations (e.g., alias counts for navigation, macro recording flag).
3. **Silent failure mode** — violating an assumption produces wrong output with no error (e.g., stale aliases when counts aren't tracked, `read` silently failing inside `bind -x`).
4. **Non-trivial lifecycle** — the feature only makes sense as a sequence of steps (e.g., mark → pack → clear in target staging).

**Do NOT add an entry** for features whose mechanism is obvious from the function names and code (e.g., `_copy_fullpath_to_clipboard` — it resolves a path and pipes to a clipboard tool; nothing hidden there).

---

## Project Overview
Nixlper is a bash helper inspired by Total Commander for Unix/Linux environments. Provides keyboard-driven file navigation, bookmarks, macros, and process management.

**Philosophy:**
- Keyboard shortcuts inspired by Total Commander
- Modular development, unified distribution
- Multiple installation methods (manual tar, RPM, DEB planned)
- Safety-first approach (confirmations, rm -i)

**Build Flow:**
```
src/main/bash/*.sh → build.sh → build/distributions/nixlper-*.tar
                              → build-rpm.sh → ~/rpmbuild/RPMS/noarch/nixlper-*.rpm
```

---

## Project Structure

```
nixlper/
├── src/main/bash/          # Individual bash modules
│   ├── nixlper.sh          # Main entry point
│   ├── functions_config.sh # Interactive config editor (nconf, migration)
│   └── functions_*.sh      # Feature modules
├── src/main/help/
│   └── help_config         # In-shell help for nconf (CTRL+X+H)
├── build.sh                # Build script (concatenation + tar packaging)
├── build-rpm.sh            # RPM build script (calls build.sh, then rpmbuild)
├── install.sh              # Manual tar-based installer (downloads from GitHub releases)
├── packaging/
│   ├── shared/
│   │   ├── nixlper.conf          # System config deployed by RPM/DEB to /etc/nixlper/
│   │   └── nixlper-profile.d.sh  # profile.d loader deployed to /etc/profile.d/nixlper.sh
│   └── rpm/
│       └── nixlper.spec          # RPM spec file
├── docs/
│   ├── index.md            # GitHub Pages home (English)
│   ├── feature-*.md        # GitHub Pages feature pages (English)
│   ├── fr/
│   │   ├── index.md        # GitHub Pages home (French)
│   │   └── feature-*.md    # GitHub Pages feature pages (French)
│   ├── _config.yml         # Jekyll config
│   └── _layouts/           # Jekyll layout overrides
├── INTERNALS.md            # Mechanism docs for non-obvious features (see "INTERNALS.md rule")
└── .claude/                # AI context files
```

---

## Features

All features are exposed through:
- **Aliases**: Short commands (e.g., `fa`, `ik`, `c`, `cf`)
- **Keybindings**: CTRL+X combinations (e.g., CTRL+X+A, CTRL+X+D)

Features are automatically discovered via `@cmd-palette` annotations in the code.

---

## Code Conventions

### Naming
- **Functions**: `snake_case`
- **Internal functions**: Prefix with `_` (e.g., `_i_log_as_error`)
- **Environment variables**: `NIXLPER_*` prefix

### Command Palette Annotations
Mark user-facing commands with:
```bash
# @cmd-palette
# @description: Brief description
# @category: Category name
# @keybind: CTRL+X+D (optional)
# @alias: shortcut (optional)
# @args: FILENAME PATTERN [REPLACEMENT] (optional)
# @interactive (optional)
function command_name() { ... }
```

**Why `@args` / `@interactive` matter — the bind -x constraint.** The palette (CTRL+X+A) is
bound via `bind -x find_action`. Inside a `bind -x` command the terminal is in readline's raw
mode, so the bash `read` builtin **cannot receive keystrokes** — any command that prompts for
input (or needs arguments typed) cannot be *executed* directly from the palette. The palette
therefore runs commands in a **hybrid** way (see `_execute_command`):

- **Plain commands** (no `@args`, no `@interactive`) are executed immediately on selection.
- **`@args` commands** and **`@interactive` commands** are *not* executed; instead the command
  is placed on the user's command line (`READLINE_LINE`), so they press Enter to run it in the
  normal shell where `read` works.

`@args` lists a command's parameters (for commands that need typed arguments); the palette
pre-fills the command name plus a trailing space so the user can type the arguments (with native
TAB completion) and press Enter. Tokens in `[brackets]` are optional. `@interactive` marks a
command that prompts internally with `read` (e.g. bookmark add/remove, `ik`, `re`); it is placed
on the command line as-is for the user to press Enter. Both still work normally via their own
keybindings/aliases — these annotations only affect how the *palette* hands them off.

All annotation lines must survive packaging: `build.sh` preserves every `# @...` comment
generically, so new annotations need no build change (see "Annotation preservation" under
Build & Installation).

### Safety Patterns
- Always use `-i` flag for rm commands
- Provide confirmation prompts
- Display commands before execution

---

## Commit Convention

All commits must follow the gitmoji format:

```
[EMOJI][WORD]|Commit message.
```

- **EMOJI** — the gitmoji character (not the `:code:`)
- **WORD** — short word signifying the commit type (see table below)
- `|` — separator between type and message
- **Commit message** — imperative, concise, ends with a period

### Examples

```
✨feat|Add fuzzy search for command shortcuts.
🐛fix|Resolve null expansion in nixlper.sh.
📟docs|Update installation guide in README.
♻️refactor|Extract key-binding logic into module.
🔧config|Add build.properties defaults.
✅test|Add unit tests for alias resolution.
🔥remove|Delete deprecated total-commander stubs.
⬆️deps|Upgrade bash minimum version requirement.
🚀deploy|Publish v1.4.0 release artifacts.
💥breaking|Drop support for zsh < 5.0.
```

### Gitmoji Reference

Source: `https://raw.githubusercontent.com/carloscuesta/gitmoji/master/packages/gitmojis/src/gitmojis.json`

| Emoji | Word | Description |
|-------|------|-------------|
| 🎨 | `style` | Improve structure or format of the code |
| ⚡️ | `perf` | Improve performance |
| 🔥 | `remove` | Remove code or files |
| 🐛 | `fix` | Fix a bug |
| 🚑️ | `hotfix` | Critical hotfix |
| ✨ | `feat` | Introduce new features |
| 📝 | `docs` | Add or update documentation |
| 🚀 | `deploy` | Deploy stuff |
| 💄 | `ui` | Add or update UI and style files |
| 🎉 | `init` | Begin a project |
| ✅ | `test` | Add, update, or pass tests |
| 🔒️ | `security` | Fix security or privacy issues |
| 🔐 | `secrets` | Add or update secrets |
| 🔖 | `release` | Release / version tags |
| 🚨 | `lint` | Fix compiler or linter warnings |
| 🚧 | `wip` | Work in progress |
| 💚 | `ci` | Fix CI build |
| ⬇️ | `downgrade` | Downgrade dependencies |
| ⬆️ | `deps` | Upgrade dependencies |
| 📌 | `pin` | Pin dependencies to specific versions |
| 👷 | `build-ci` | Add or update CI build system |
| 📈 | `analytics` | Add or update analytics or tracking code |
| ♻️ | `refactor` | Refactor code |
| ➕ | `add-dep` | Add a dependency |
| ➖ | `rm-dep` | Remove a dependency |
| 🔧 | `config` | Add or update configuration files |
| 🔨 | `script` | Add or update development scripts |
| 🌐 | `i18n` | Internationalization and localization |
| ✏️ | `typo` | Fix typos |
| ⏪️ | `revert` | Revert changes |
| 🔀 | `merge` | Merge branches |
| 📦️ | `package` | Add or update compiled files or packages |
| 👽️ | `api` | Update code due to external API changes |
| 🚚 | `move` | Move or rename resources |
| 📄 | `license` | Add or update license |
| 💥 | `breaking` | Introduce breaking changes |
| 🍱 | `assets` | Add or update assets |
| ♿️ | `a11y` | Improve accessibility |
| 💡 | `comment` | Add or update source code comments |
| 💬 | `text` | Add or update text and literals |
| 🗃️ | `db` | Perform database related changes |
| 🔊 | `log` | Add or update logs |
| 🔇 | `no-log` | Remove logs |
| 🏗️ | `arch` | Make architectural changes |
| 🩹 | `patch` | Simple fix for non-critical issue |
| ⚰️ | `dead` | Remove dead code |
| 🧪 | `test-fail` | Add a failing test |
| 🏷️ | `types` | Add or update types |
| 🌱 | `seed` | Add or update seed files |
| 🚩 | `flag` | Add, update, or remove feature flags |
| 🥅 | `catch` | Catch errors |
| 🗑️ | `deprecate` | Deprecate code needing cleanup |
| 🛂 | `auth` | Work on authorization, roles, permissions |
| 🧐 | `explore` | Data exploration or inspection |
| 🦵 | `validate` | Add or update validation code |
| 🧵 | `thread` | Add or update multithreading or concurrency code |

---

## Development Workflow

### Before Coding
1. Show plan/outline to user
2. Discuss approach and architecture

### Development
1. Modify modules in `src/main/bash/`
2. Test modules individually
3. Follow naming conventions
4. Add @cmd-palette annotations for user commands

### Before Commit
1. Build with `./build.sh`
2. Test installation
3. Verify keyboard bindings work

### After every push — MANDATORY CI check

After every `git push`, **always verify CI passes** before reporting the task as done:

1. Wait ~30 s, then poll `mcp__github__actions_list` (`list_workflow_runs`, branch filter) until
   the latest run reaches `status: completed`.
2. If `conclusion: success` → report done.
3. If `conclusion: failure` → fetch logs with `mcp__github__get_job_logs`
   (`failed_only: true`, `return_content: true`), diagnose the failure, fix it, push again,
   and repeat from step 1.
4. **Never hand back to the user with a red CI.** If a failure is genuinely out of scope or
   requires a decision, explain the failure and the options — do not silently leave CI broken.

### Testing requirement (bugs and features)
After implementing a bug fix or a new feature, **always test it** before committing:
- Source the affected module(s) in a subshell and exercise the changed function directly.
- Cover at minimum: the fixed/new case, a regression case (existing behaviour unchanged), and an error/edge case.
- If testing is genuinely impossible in the current environment (missing runtime dependency, interactive terminal required, etc.), **explicitly warn the user** before committing — never silently skip testing.

### Configurability check — for every new feature
When adding a new feature, ask: **can this behaviour reasonably vary per user?** If yes, it must be configurable via `nconf`:
1. Add a `NIXLPER_*` variable with a sensible default to `_NIXLPER_CONFIG_VARS` in `functions_config.sh`.
2. Use `${NIXLPER_MY_VAR:-default}` everywhere the feature reads the setting.
3. Add the variable (commented-out) to `_nconf_create_user_conf` so new installs get it as documentation.
4. Add it to the system conf template in `_i_install_system` (nixlper.sh) with a `:-` guard.
5. Update `CLAUDE.md → Environment Variables` table and both doc locations (README + help file).

Examples of things that should be configurable: timeouts, default modes, on/off toggles for output, paths.

### Bug sweep — MANDATORY before every commit
Before committing any feature or fix, **actively scan the code you wrote or touched for bugs**:
- Read each new/modified function end-to-end and ask: "What breaks if the input contains special characters? What if the file doesn't exist yet? What if this runs twice?"
- Check every interaction with pre-existing code: does the new code change assumptions that older functions relied on? (Example: a new config file changes where settings live — does the installer still handle the old location correctly?)
- If you find a bug, fix it in the same commit. If it is out of scope, add it to `KNOWN_ISSUES.md` before committing.
- **Never hand work back to the user with known, unaddressed bugs unless they are explicitly deferred and tracked.**

### Command palette rendering check (MANDATORY for every new command)
After adding any new command (function + `@cmd-palette` annotation, or alias-based), **verify it renders correctly in the palette** before committing:

```bash
# Source the module and run the registry builder; grep for your new command
source src/main/bash/functions_command_palette.sh
source src/main/bash/<your_module>.sh
_build_command_registry | grep "^<your_command>|"
# Then verify the formatted display line looks right
_build_command_registry | grep "^<your_command>|" | while IFS= read -r line; do _format_command_for_display "$line"; done
```

Check that:
- The command name, description, category appear correctly.
- The keybind column shows `[CTRL+X+?]` for keybind commands, or `[alias: <name>]` for alias-only commands. A blank keybind column is **acceptable** when the command has no `@keybind` or `@alias`. It is **never acceptable** when a keybind or alias is defined but not displayed.
- `[alias]` type indicator is present for alias-based commands.
- `@args` / `@interactive` commands are placed on the command line (not executed) when selected — verify `_execute_command` receives the right flags.

### Unit test files (new features)
Every new feature module should be accompanied by a unit test file:
- Location: `src/test/bash/test_functions_<module>.sh`
- Pattern: pure bash, no external framework, network helpers mocked — follow the existing example in `src/test/bash/test_functions_update.sh`.
- The test file must be runnable standalone: `bash src/test/bash/test_functions_<module>.sh`
- Add a named step in `.github/workflows/tests.yml` to run it: `bash src/test/bash/test_functions_<module>.sh` (CI does not auto-discover test files — each must be added explicitly).

Existing feature modules do **not** have unit test files yet — this is tracked as a debt item in `KNOWN_ISSUES.md`. Do not add tests for existing modules unless explicitly asked.

---

## Adding New Features

### New Feature
1. **If related to existing module** (e.g., clipboard, navigation, files):
   - Add to existing `functions_*.sh` file
   - Example: clipboard features → `functions_clipboard.sh`

2. **If completely new domain**:
   - Create new `src/main/bash/functions_feature_name.sh`

3. For both cases:
   - Define functions with clear names (use `_` prefix for internal)
   - Add @cmd-palette annotations for user-facing commands
   - Build will automatically include it

### Tri-location documentation rule
Feature documentation lives in **three places** that must always stay in sync:

| Location | Role |
|---|---|
| `docs/feature-*.md` (GitHub Pages — English) | User-facing reference (English) |
| `docs/fr/feature-*.md` (GitHub Pages — French) | User-facing reference (French) |
| `src/main/help/help_<category>` | In-shell help (CTRL+X+H) |

**When adding or modifying a feature, update all three locations in the same commit.**

`README.md → ## Features` is intentionally a brief summary table — do not add command details there.

To check for drift, compare the relevant `docs/feature-*.md` page, its `docs/fr/feature-*.md` counterpart, and the corresponding `src/main/help/help_<category>` file. Every command, alias, and keybinding mentioned in one must appear in all three. Flag any discrepancy to the user before closing a session that touched features.

### Release process — CHANGELOG.md and README.md

> **Mobile-friendly release convention:** Release commits go **directly to `main`** — no feature
> branch, no PR. Pushing a commit whose message starts with `🔖release|Release v` to `main`
> automatically triggers `create_release_on_tag.yml`, which creates the git tag, builds the
> tar/RPM/DEB artifacts, extracts the CHANGELOG entry, and publishes the GitHub release.
> Nothing to do on mobile — no manual tag push, no GitHub UI interaction needed.
>
> **How to trigger a release:** just say *"make a release vX.Y.Z"*. Claude handles the rest.

Every release requires updating **two files** in the same commit (CI creates the git tag automatically).

#### CHANGELOG.md
`CHANGELOG.md` is the authoritative history of all changes. It follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Fixed
- ...

### Removed
- ...
```

**How to populate a new entry:** read the commits since the previous tag with
`git log --pretty=format:"%ad %s" --date=short vPREV..vNEW` and group them into
`Added`, `Fixed`, `Changed`, or `Removed` sections. Filter out pure doc/CI/build
commits unless they affect users. Write entries in plain English, not as raw commit
messages.

**PATCH** (`X.Y.Z+1`) — bug fixes only, no new features.  
**MINOR** (`X.Y+1.0`) — new features, backward-compatible.  
**MAJOR** (`X+1.0.0`) — breaking changes or a significant paradigm shift.

#### README.md
The opening badge block of `README.md` contains the current version and a one-line "What's new" summary:

```markdown
> 🚀 **Current version: vX.Y.Z** — [Release notes](https://github.com/Minhounet/nixlper/releases)
>
> **What's new in vX.Y.Z:** One-sentence summary of the key changes (distilled from the CHANGELOG.md entry).
>
> Nixlper evolves constantly...
```

When cutting a release, update both:
1. The version number on the badge line.
2. The **"What's new"** line — write a concise one-sentence summary of the main additions, fixes, or changes from the `CHANGELOG.md` entry for the new version.

#### Tagging — complete release sequence

Releases commit directly to `main` (no PR). The full sequence in one shot:

```bash
# 1. Ensure you are on main and up to date
git checkout main
git pull origin main

# 2. Commit the release (CHANGELOG + README already updated above)
git commit -m "🔖release|Release vX.Y.Z."

# 3. Push to main — CI does the rest
git push -u origin main
```

Pushing the release commit triggers `create_release_on_tag.yml` (which detects the
`🔖release|Release v` prefix), creates the git tag, builds the tar/RPM/DEB artifacts,
extracts the CHANGELOG entry, and publishes the GitHub release automatically. No manual
tag push or GitHub UI interaction needed.

The build picks up the tag automatically via `git describe --tags --exact-match HEAD`.

### New Keyboard Shortcut
```bash
# In _i_load_bindings() function in nixlper.sh
bind -x '"\C-x\C-y": your_function_name'  # CTRL+X then Y
```

---

## Build & Installation

### Build tar (all platforms)
`build.sh` concatenates all `src/main/bash/function*.sh` files, merges with `nixlper.sh`,
strips comments, and creates `nixlper-VERSION.tar` in `build/distributions/`. Requires `dos2unix`.

**Annotation preservation (important).** The strip step keeps **every `# @...` comment line**
generically (`sed '/^#[[:space:]]*@/!{/^#.*/d}'`), so all command-palette annotations
(`@cmd-palette`, `@description`, `@category`, `@keybind`, `@alias`, `@template`, `@args`,
`@interactive`, and any added later) survive into the built/installed `nixlper.sh`. Do **not**
reintroduce a hand-maintained whitelist here: an annotation missing from the build is invisible
to the runtime parser, which silently breaks palette behavior in packaged installs (RPM/DEB/tar)
while still working in the dev source tree — a confusing class of "works in dev, broken when
built" bug. When adding a new annotation, no change to `build.sh` is needed.

### Manual install (tar-based, any Unix)
```bash
bash build.sh
mkdir -p /opt/nixlper && tar -xf build/distributions/nixlper.tar -C /opt/nixlper
cd /opt/nixlper && ./nixlper.sh install   # writes to ~/.bashrc
source ~/.bashrc
```

### Update / Uninstall (manual)
```bash
./nixlper.sh update     # rewrites ~/.bashrc block, preserves user data
./nixlper.sh uninstall  # removes ~/.bashrc block
```

### Build RPM (RHEL/Fedora/Rocky — requires rpm-build)
```bash
bash build-rpm.sh
# RPM lands in ~/rpmbuild/RPMS/noarch/
```

---

## Environment Variables

All variables follow a precedence chain — later sources override earlier ones:

1. `/etc/nixlper/nixlper.conf` — system defaults (RPM/DEB managed, uses `:-` so it never overrides already-set vars)
2. `~/.config/nixlper/nixlper.conf` — per-user overrides (highest precedence; managed by `nconf`)
3. `~/.bashrc` — legacy manual install only; **deprecated** for storing settings (see migration below)

**Manual install — new behaviour (post-migration):** `~/.bashrc` contains only `source /opt/nixlper/nixlper.sh`.
All settings live in `~/.config/nixlper/nixlper.conf`, created at install time with `NIXLPER_INSTALL_DIR` set
and all other vars commented out as documentation. `nconf` (CTRL+X+C) prompts for migration on first run
when old-style `export NIXLPER_*` lines are detected in `~/.bashrc`.

Actual precedence (lowest → highest):
```
/etc/nixlper/nixlper.conf  <  ~/.bashrc exports  <  ~/.config/nixlper/nixlper.conf
```

| Variable | Manual install default | RPM/DEB default |
|---|---|---|
| `NIXLPER_INSTALL_DIR` | user-chosen dir (e.g. `/opt/nixlper`) | `/usr/share/nixlper` |
| `NIXLPER_BOOKMARKS_FILE` | `$NIXLPER_INSTALL_DIR/.nixlper_bookmarks` | `~/.local/share/nixlper/bookmarks` |
| `NIXLPER_LAST_MACRO_BINDING_FILE` | `$NIXLPER_INSTALL_DIR/.nixlper_last_macro_binding_file` | `~/.local/share/nixlper/last_macro_binding` |
| `NIXLPER_SNAPSHOT_DIR` | `$NIXLPER_INSTALL_DIR/snapshots` | `~/.local/share/nixlper/snapshots` |
| `NIXLPER_CUSTOM_DIR` | `$NIXLPER_INSTALL_DIR/custom` | `~/.config/nixlper/custom` |
| `NIXLPER_NAVIGATE_MODE` | `tree` | `tree` |
| `NIXLPER_EDITOR` | `vim` | `vim` |
| `NIXLPER_DISABLE_WELCOME_MESSAGE` | `false` | `false` |
| `NIXLPER_DISABLE_TIPS` | `false` | `false` |
| `NIXLPER_UPDATE_CHANNEL` | `stable` | `stable` |
| `NIXLPER_UPDATE_CHECK` | `true` | `true` |
| `NIXLPER_UPDATE_AUTO` | `false` | `false` |
| `NIXLPER_UPDATE_CHECK_INTERVAL` | `86400` | `86400` |
| `NIXLPER_UPDATE_TIMEOUT` | `2` | `2` |
| `NIXLPER_UPDATE_CACHE_FILE` | `$NIXLPER_INSTALL_DIR/.nixlper_update_check` | `~/.local/share/nixlper/update_check` |

`NIXLPER_SNAPSHOT_DIR` and `NIXLPER_CUSTOM_DIR` are resolved inside nixlper.sh with `:-` fallbacks
to `$NIXLPER_INSTALL_DIR/snapshots` and `$NIXLPER_INSTALL_DIR/custom` when not explicitly set.

### Update detection (`functions_update.sh`)

Two channels selected via `NIXLPER_UPDATE_CHANNEL`: `stable` (compares installed `VERSION:`
against GitHub `releases/latest`), `edge` (compares installed full `COMMIT:` SHA against the
`target_commitish` of the rolling `edge` pre-release — **not** raw `main` HEAD), and `off`.
All network access is gated by `_i_is_online` — a time-boxed `curl` reachability probe — so
an offline machine never hangs or errors at login. Automatic startup checks are throttled via
`NIXLPER_UPDATE_CACHE_FILE`; the `nu` / `CTRL+X+W` command bypasses the throttle and always
reports. The `edge` channel relies on `build.sh` writing the full SHA (`COMMIT:`) into the
`version` file, and on CI's rolling `edge` pre-release
(`.github/workflows/publish_edge_on_push.yml`), which skips release commits (prevents a race
where `vX.Y.Z` is embedded in the edge artifact and a false-positive update loop) and is
excluded from `create_release_on_tag.yml` via a `!edge` tag filter. `install.sh` accepts `--channel
stable|edge` and `--yes`, and aborts cleanly when the internet is unreachable.

Automated tests live in `src/test/bash/test_functions_update.sh` (pure bash, no framework,
fully offline — network helpers are mocked). They run in CI via `.github/workflows/tests.yml`
on every push and PR, alongside a `bash -n` syntax check of all bash sources. Run locally with
`bash src/test/bash/test_functions_update.sh`.

---

## RPM Packaging

### How it works
- `/etc/profile.d/nixlper.sh` (single line: `source /usr/share/nixlper/nixlper.sh`) activates nixlper for all users at login — no `.bashrc` changes needed.
- nixlper.sh itself loads the config chain: `/etc/nixlper/nixlper.conf` then `~/.config/nixlper/nixlper.conf`.
- User data (`bookmarks`, `snapshots/`, `custom/`) is created on first login under `~/.local/share/nixlper/` and `~/.config/nixlper/` — never owned or modified by the RPM.

### Building the RPM
```bash
# Requires: rpmbuild (dnf install rpm-build on RHEL/Fedora/Rocky)
bash build-rpm.sh
# Output: ~/rpmbuild/RPMS/noarch/nixlper-VERSION-1.noarch.rpm
```

### Install / upgrade / uninstall
```bash
dnf install nixlper-VERSION.noarch.rpm   # first install
dnf upgrade nixlper-VERSION.noarch.rpm   # upgrade — /etc/nixlper/nixlper.conf preserved
dnf remove nixlper                        # uninstall — user data untouched
```

### Key RPM spec decisions
- `BuildArch: noarch` — pure bash, no compilation
- `%config(noreplace)` on `/etc/nixlper/nixlper.conf` — admin edits survive upgrades
- `/etc/profile.d/nixlper.sh` is NOT `%config` — it is always replaced on upgrade
- `Requires: bash >= 4.0` / `Recommends: vim, tree`
- `%post` and `%preun` are intentionally empty

### Compatibility with manual install
The same `nixlper.sh` binary supports both install methods. When `/etc/nixlper/nixlper.conf`
is absent (manual install), all vars fall back to `NIXLPER_INSTALL_DIR`-relative paths.
The double-load guard (`NIXLPER_LOADED`) prevents double initialisation if both `.bashrc`
and profile.d are active simultaneously during migration.

---

## DEB Packaging

Native DEB is planned (next session). Key difference from alien-converted DEB:
- Only `/etc/nixlper/nixlper.conf` should be listed in `DEBIAN/conffiles` (admin-editable).
- `/etc/profile.d/nixlper.sh` must NOT be a conffile — it should be removed cleanly on `dpkg -r`.
- Shared source files: `packaging/shared/nixlper.conf` and `packaging/shared/nixlper-profile.d.sh`.

---

## Testing Checklist

- [ ] Test in Git Bash and Linux
- [ ] Validate keyboard bindings
- [ ] Run shellcheck if safe
- [ ] Test build and installation (`bash build.sh && tar -xf ... && ./nixlper.sh install`)
- [ ] RPM: `bash build-rpm.sh` on a RHEL/Fedora/Rocky system, then `dnf install`
- [ ] **Doc sync check**: verify every command in `docs/feature-*.md` (GitHub Pages) matches its `src/main/help/help_*` counterpart, and vice versa (see "Dual-location documentation rule" above)
