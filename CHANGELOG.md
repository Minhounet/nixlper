# Changelog

All notable changes to this project will be documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **`INTERNALS.md`**: documents the mechanism behind non-obvious features — macro
  `PROMPT_COMMAND` recording, navigation alias namespace/cleanup, command palette
  `bind -x` dispatch, target staging lifecycle, and update detection
  channels/throttling.

### Fixed
- **DEB version on release builds**: `build-deb.sh` now detects an exact git tag and
  strips the leading `v` (matching RPM behaviour); untagged builds fall back to
  `0~<sha>`. Release DEBs now carry a meaningful version number.
- **Update check always reporting offline**: `_i_is_online` was probing
  `https://api.github.com` which returns HTTP 403 in unauthenticated cloud/CI
  environments; curl's `-f` flag treats 4xx as failure, so nixlper always skipped
  the update check. Probe changed to `https://github.com` (reliably returns 200).
  Also removed `-f` from the three API endpoint helpers — those return valid JSON
  on individual endpoints even when the root is 403, and `-f` was silently discarding
  successful API responses.
- **Edge channel false update loop**: the update check now fetches the SHA from
  `/releases/tags/edge` (via `_i_remote_edge_release_commit()`) instead of raw
  `main` HEAD, so a release commit that advances `main` without publishing a new
  edge artifact no longer triggers a spurious "update available" prompt.
- **Edge CI race on release commits**: `publish_edge_on_push.yml` now skips when the
  commit message starts with `🔖release|`, preventing a race where the release tag
  was already present at edge-build time and the wrong version got embedded in the
  edge artifact.
- **Stale navigation aliases**: `functions_navigation.sh` now tracks the previous
  alias count and unaliases stale `v*/n*/d*/tc*/tm*/cdf*` shortcuts before
  regenerating them, so switching to a smaller directory no longer leaves phantom
  shortcuts from the previous (larger) listing.
- **Macro recording reliability**: macro recording no longer scrapes `~/.bash_history`;
  it now uses a `PROMPT_COMMAND` hook that appends each command into an in-memory
  array. `sr`/`fr` invocations are excluded automatically.

### Changed
- **`_i_get_pid_by_port()`**: tries `ss` first, falls back to `netstat`, and errors
  cleanly when neither is installed.

---

## [2.2.0] - 2026-06-13

### Added
- **`nconf` interactive config editor** (`CTRL+X+C`, alias `nconf`): a menu-driven editor for
  all `NIXLPER_*` settings that reads from and writes to `~/.config/nixlper/nixlper.conf`.
  Each setting is displayed with its current value and a short description; selecting one
  prompts for a new value and saves it immediately.
- **`.bashrc` migration**: on first `nconf` run, any old-style `export NIXLPER_*` lines
  detected in `~/.bashrc` are offered for migration to `~/.config/nixlper/nixlper.conf`,
  then stripped from `~/.bashrc` to avoid double-export conflicts.
- **Automated CI release**: pushing a `🔖release|Release v` commit to `main` now automatically
  creates the git tag and publishes the GitHub release — no manual tag push needed.

---

## [2.1.0] - 2026-06-10

### Added
- **Target staging** (`functions_target.sh`): accumulate files from anywhere and copy or pack
  them into a shared, world-readable folder (default `/tmp/nixlper_target`).
  - `tc FILEPATH` / `tcN` — copy a file to the target folder immediately (`chmod 644`).
  - `tm FILEPATH` / `tmN` — mark a file for a later batch pack (no-op if already marked).
  - `tml` — list currently marked files with index numbers.
  - `tum` — interactively remove a mark by number.
  - `tcm` — clear all marks without copying anything.
  - `tp` / `CTRL+X+Y` — pack all marked files into a timestamped `.tgz` in the target folder, then clear marks.
  - `tsd [DIRPATH]` — show or change the target folder for the current session.
  - `tclean` — delete all files in the target folder (confirmation required).
  - `tcN` and `tmN` shortcuts also appear in `CTRL+X+N` navigate and `fan` results.
- **Navigate/fan per-file shortcuts** (`CTRL+X+N`, `fan`): each listed file now offers
  `cdfN` (cd to its folder), `dN` (delete it), `tcN` (copy to target), and `tmN` (mark for pack),
  in addition to the existing `vN` (open) and `nN` (navigate) shortcuts.
- **RPM and DEB update support**: `nu` detects the install method (tar / RPM / DEB) and runs
  the appropriate update command (`bash install.sh`, `dnf upgrade`, or `apt install`).
  Edge channel also publishes `.rpm` and `.deb` artefacts on every push to `main`.
- **`nw` alias** for `show_ongoing_work` (mirrors the existing `CTRL+X+W` binding).
- **Update detection with channels** (`NIXLPER_UPDATE_CHANNEL`): `stable` tracks tagged
  releases and suggests an update when a newer tag exists; `edge` tracks the latest commit
  via a rolling pre-release; `off` disables checks entirely.
- On-demand update check: `nu` / `CTRL+X+W`. An automatic, throttled check also runs at shell
  start (`NIXLPER_UPDATE_CHECK_INTERVAL`, default 24h).
- Offline-safe: a fast reachability probe (`NIXLPER_UPDATE_TIMEOUT`) gates all network access,
  so checks are skipped silently when the internet is unreachable.
- Opt-in auto-update (`NIXLPER_UPDATE_AUTO`, default off).
- `install.sh` gains `--channel stable|edge` and `--yes` (non-interactive), plus an internet
  reachability check that aborts cleanly when offline.
- CI publishes a rolling `edge` pre-release (`nixlper-edge.tar`) on every push to `main`.

### Fixed
- **`sn` false-success on absolute paths**: absolute paths are now detected before prepending
  `$(pwd)/`, and copy failures are reported correctly instead of always printing "has been saved".
- **`fan` silent path-with-spaces bug**: `IFS=$'\n'` is now set before the find-results loop,
  matching the pattern already used by `fag`, so file paths containing spaces are handled correctly.
- **False stable-update prompt on edge installs**: the update check now skips the stable prompt
  when the installed build is from the edge channel.

### Changed
- The build now records the full commit SHA (`COMMIT:`) in the version file for edge comparison.

---

## [2.0.1] - 2026-06-07

### Fixed
- Command palette printing the list twice after executing a command.
- Command palette header border misalignment.

---

## [2.0.0] - 2026-06-06

A major release that turns Nixlper from a personal script collection into a
properly packaged, discoverable tool.

### Added
- **Command palette** (`CTRL+X+A`): fuzzy-searchable popup of every command with
  description, category, keybinding, and alias. Supports `@args` and `@interactive`
  annotations so commands that need user input are placed on the command line
  instead of being executed blindly.
- `bind` command execution from the palette.
- **RPM and DEB packages** — install via your system package manager.
- **`install.sh`** — one-liner curl install and self-update script.
- **`fag`** — grep files and jump to the matching line in your editor.
- **`fan` shortcuts** — `d1`/`d2`/… delete found files; `cdf1`/`cdf2`/… cd into the
  folder of each found file.
- **`rn`** — rename files by pattern.
- **`rf`** — refresh current directory view.
- **Tips system** — surfaces a tip at every shell start; configurable with
  `NIXLPER_DISABLE_TIPS` and sequential or random display modes.
- Missing-tool detection at startup: reports exactly what to install.
- `NIXLPER_DISABLE_WELCOME_MESSAGE` option to suppress startup output.
- `build.properties` support for local install/update paths.
- `CLAUDE.md` and `KNOWN_ISSUES.md` added to the repository.

### Fixed
- v-prefix mismatch that caused the tar archive not to be found in RPM and DEB builds.

---

## [1.8.0] - 2026-01-03

### Added
- **`cpcb`** — copy file full path to clipboard.
- **`cpdcb`** — copy directory path to clipboard.
- Nixlper logo and version info displayed at startup.
- Fuzzy search inside the in-shell help (`CTRL+X+H`).
- Save and restore last macro binding across sessions.
- Architecture section added to `README.md`.

---

## [1.7.0] - 2025-09-16

### Added
- **`re`** — record terminal session (macro recording feature).

---

## [1.6.0] - 2025-09-12

### Added
- **`ap`** — prepend current path to `PATH` via `.bashrc`.
- Configurable editor via `NIXLPER_EDITOR` environment variable.
- `shunit2` test framework integrated into the project.
- Unit tests for `functions_logging.sh`.
- Tests are automatically run during `build.sh`.

---

## [1.5.0] - 2025-01-20

### Added
- File permissions displayed during navigation when toggle mode is active.

---

## [1.4.0] - 2024-06-18

### Added
- Item length (size) displayed during file navigation.

---

## [1.3.0] - 2024-04-19

### Added
- **`fan`** (`find_and_navigate`) — search for files and navigate into results
  with a tree-style display.

---

## [1.2.0] - 2024-03-29

### Added
- **`ik`** — interactive kill by process pattern (repeats until no match remains).
- Kill by port number.
- **Snapshot feature** — save and restore shell session state.
- Version number sourced from git tag at build time.

---

## [1.1.0] - 2024-02-16

### Added
- **Tree navigation mode** (`NIXLPER_NAVIGATE_MODE=tree`) alongside the existing
  `ls` mode.
- Folder navigation shortcuts `1`–9` bound to the nine most recent directories.
- Custom scripts folder (`NIXLPER_CUSTOM_DIR`) loaded at startup; duplicate aliases
  are rejected.
- Configuration install refactored for cleaner `.bashrc` integration.

### Fixed
- Error when writing version during install.
- Missing default value when creating a bookmark.

---

## [1.0] - 2024-01-11

Initial release.

### Added
- Bookmark directory functions (`c`, `cf`).
- `cdf` — cd into the folder containing a given filepath.
- Set-current-folder shortcut.
- Gradle-based build producing a distributable archive.
