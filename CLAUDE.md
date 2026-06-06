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
│   └── functions_*.sh      # Feature modules
├── build.sh                # Build script (concatenation + tar packaging)
├── build-rpm.sh            # RPM build script (calls build.sh, then rpmbuild)
├── install.sh              # Manual tar-based installer (downloads from GitHub releases)
├── packaging/
│   ├── shared/
│   │   ├── nixlper.conf          # System config deployed by RPM/DEB to /etc/nixlper/
│   │   └── nixlper-profile.d.sh  # profile.d loader deployed to /etc/profile.d/nixlper.sh
│   └── rpm/
│       └── nixlper.spec          # RPM spec file
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
📝docs|Update installation guide in README.
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
| 🦺 | `validate` | Add or update validation code |
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

### Dual-location documentation rule
Feature documentation lives in **two places** that must always stay in sync:

| Location | Role |
|---|---|
| `README.md` → `## Features` → `### <Category>` | Public-facing reference |
| `src/main/help/help_<category>` | In-shell help (CTRL+X+H) |

**When adding or modifying a feature, update both locations in the same commit.**

To check for drift between the two at any time, compare each `### <Category>` block in `README.md` with the corresponding `src/main/help/help_<category>` file. Every command, alias, and keybinding mentioned in one must appear in the other. Flag any discrepancy to the user before closing a session that touched features.

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

1. `/etc/nixlper/nixlper.conf` — system defaults (RPM/DEB managed, uses `:-` so it never overrides vars already set by `~/.bashrc`)
2. `~/.config/nixlper/nixlper.conf` — per-user overrides
3. `~/.bashrc` — manual install sets vars here before sourcing nixlper.sh

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

`NIXLPER_SNAPSHOT_DIR` and `NIXLPER_CUSTOM_DIR` are resolved inside nixlper.sh with `:-` fallbacks
to `$NIXLPER_INSTALL_DIR/snapshots` and `$NIXLPER_INSTALL_DIR/custom` when not explicitly set.

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
- [ ] **Doc sync check**: verify every command in `README.md → ## Features` matches its `src/main/help/help_*` counterpart, and vice versa (see "Dual-location documentation rule" above)
