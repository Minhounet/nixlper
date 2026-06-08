# Changelog

All notable changes to this project will be documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
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
- Folder navigation shortcuts `1`–`9` bound to the nine most recent directories.
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
