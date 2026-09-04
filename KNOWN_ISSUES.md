# Known Issues

This file tracks confirmed defects that are **not** yet fixed. Each entry is reproducible
and verified. These are intended to be addressed in dedicated follow-up sessions.

> Referenced from `CLAUDE.md`. When an issue here is fixed, remove it from this file in the
> same commit and (if user-facing) update `README.md` / `src/main/help/*` per the dual-location rule.

### Impact legend

| Level | Meaning |
|---|---|
| 🔴 **Blocking** | Command/feature is unusable, or causes data loss with no warning. Fix first. |
| 🟠 **Important** | Works in the common case but silently produces wrong results or misleads the user in real scenarios. |
| 🟡 **Minor** | Cosmetic, noisy, or doc-only. No functional impact on results. |

---

## Experimental features (untested in live environments)

### 🟠 SSH connection manager (`sc`, `sca`, `scr`, `scl`, `CTRL+X+S`) — untested

The SSH connection manager was implemented and unit-tested with mocks (offline),
but has not yet been exercised against a real SSH server or in a live MobaXterm/terminal
session. All four commands display a warning banner at startup.

Known untested scenarios: `ssh-copy-id` behaviour across different OS versions, key
permission edge cases, hosts with `PasswordAuthentication no` already set, and MobaXterm
terminal compatibility. Remove this entry once the feature has been validated in a live session.

---

## Direct-usage bugs (independent of the command palette)

These bugs occur when the command is invoked **directly** on the command line with its
documented arguments — they are not related to the `find_action` (CTRL+X+A) palette.

### 🟡 `_i_navigate_tree` uses wrong variable for the CTRL+X+N digit-binding guard

In `_i_navigate_tree` (`functions_navigation.sh`), the guard that limits `bind -x '"\C-x<N>"'`
keybindings to folder indices 1–9 reads `if [[ ${increment} -lt 10 ]]` but the variable
tracking the folder index is `folder_increment`, not `increment`. Because `increment` is never
set in that function, it is always empty — bash treats an empty string as `0` in arithmetic
comparison, so `0 < 10` is always true. Every folder, regardless of its actual index, gets a
`\C-x<N>` binding. For indices 1–9 this is harmless (correct behavior). For index 10+, bash
creates a `\C-x10` binding (CTRL+X then '1' then '0'), which is a two-character sequence and
effectively a dead key — it is never triggered by a user keystroke, but it does add noise to
`bind -p` output and slightly pollutes readline's key table. Fix: replace `${increment}` with
`${folder_increment}` on that line.

### 🟡 Bookmarked directories containing spaces break when the bookmark's alias is typed directly

`_i_bookmark_directory` (`functions_bookmarks.sh`) writes the bookmark as
`alias NAME='cd $bookmarked_dir && ...'` with the path interpolated **unquoted**. Bookmarking a
directory whose path contains a space (e.g. `/home/user/my projects/dir`) stores a `cd` that
word-splits when the alias is typed directly, so `cd` receives multiple arguments and fails or
lands in the wrong place. Discovered while adding the `bd` / `CTRL+X+D` fuzzy/numbered picker
(see `INTERNALS.md` → Bookmarks), which does *not* have this problem — it `cd`s to the
properly-quoted path it parsed, bypassing the stored alias entirely. Only direct invocation of
the alias name is affected. Fix requires quoting the path at write time and updating the read
side to tolerate both quoted (new) and unquoted (existing, already-installed) bookmark files.

### 🟡 `lc` (last command) can misorder multi-line history entries under `shopt -s lithist`

`_i_last_command_history_raw` (`functions_last_command.sh`) reads bash's `history` builtin output
line-by-line and reverses it with `tac` to get most-recent-first order. By default (`lithist`
off, `cmdhist` on — the vast majority of interactive setups) bash flattens multi-line commands
(e.g. a `for` loop typed across several lines) into a single history entry joined with
semicolons, so this works correctly. If a user has explicitly enabled `shopt -s lithist`, bash
instead embeds literal newlines inside a single history entry, which `tac`'s line-level reversal
splits apart and reorders along with unrelated entries — the affected entry shows up garbled or
merged with a neighbour in `lc`'s list. Fix requires joining each history entry's physical lines
before reversing (e.g. an `awk` pass keyed on the leading `NUM  ` index) rather than reversing
raw lines. Not fixed because `lithist` is off by default and the common case (single-line
commands, or multi-line ones bash already flattens) is unaffected.

### 🟡 Macros: commands requiring interactive input silently do nothing on replay

`CTRL+X+CTRL+X` replay runs inside a `bind -x` callback where readline raw mode is active.
Any recorded command that internally calls `read` (e.g. `ik`, `re`, bookmark commands) will
be silently skipped or block during replay. The recording itself works fine — only replay is
affected. Workaround: do not record interactive commands in a macro.

## Documentation drift (dual-location rule)

Per CLAUDE.md, every command in `README.md → ## Features → ### <Category>` must also appear in
the matching `src/main/help/help_<category>` file, and vice versa.

## Technical debt

### 🟡 No unit tests for existing feature modules

Only `functions_update.sh` has a unit test file (`src/test/bash/test_functions_update.sh`).
All other modules (`functions_clipboard.sh`, `functions_navigation.sh`, `functions_files.sh`,
`functions_bookmarks.sh`, `functions_processes.sh`,
`functions_command_palette.sh`, etc.) have no automated tests.
`functions_macros.sh` gained tests when its implementation was rewritten
(`src/test/bash/test_functions_macros.sh`).

New feature modules must include a test file (see CLAUDE.md → "Unit test files"). Retrofitting
tests for existing modules is welcome but not required — tackle one module at a time when
touching that module for another reason.

---

## Notes

- The command palette's inability to pass arguments to argument-taking commands is **not** a bug
  in those commands — it is a palette limitation addressed separately by the `@args` annotation
  mechanism in `functions_command_palette.sh`. Commands called directly with their arguments
  work as designed (except for the two issues above).
