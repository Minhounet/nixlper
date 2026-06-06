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

## Direct-usage bugs (independent of the command palette)

These bugs occur when the command is invoked **directly** on the command line with its
documented arguments — they are not related to the `find_action` (CTRL+X+A) palette.

### ISSUE-1 — `fan` / `fag` silently miss paths containing spaces

- **Impact:** 🟠 Important — the command appears to work (exit 0) but silently omits matches,
  so the user can wrongly conclude "no such file". Only triggers when a path contains a space.
- **Commands:** `fan` (`_find_and_navigate`), `fag` (`_grep_and_navigate`)
- **Files:** `src/main/bash/functions_navigation.sh:185` (`for i in ${find_results}`)
  and `src/main/bash/functions_navigation.sh:237` (`for i in ${grep_results}`)
- **Symptom:** A file whose path contains a space is never listed, and no `v#`/`cdf#`/`n#`/`d#`
  alias is created for it. The command exits 0 and appears to "find nothing".
- **Reproduction:**
  ```bash
  mkdir -p "my dir" && echo x > "my dir/space file.txt"
  fan space      # prints ".." / ".." with zero matches
  ```
- **Root cause:** The unquoted `for i in ${find_results}` / `${grep_results}` word-splits each
  path on whitespace (IFS), so a path like `./my dir/space file.txt` is broken into separate
  words and fails the `[[ -f $i ]]` / `[[ -d $i ]]` tests.
- **Suggested fix:** Iterate with a NUL/newline-safe loop, e.g.
  `find . -iname "*${pattern}*" -print0 | while IFS= read -r -d '' i; do ...`.
  Note `fag` already sets `IFS=$'\n'` for its loop but `fan` does not; align both and make them
  space-safe.

### ISSUE-2 — `sn` reports false success on an absolute path

- **Impact:** 🟠 Important (severe when triggered) — prints "has been saved" and returns 0 while
  nothing was copied. A user who trusts that message and later edits/deletes the original can
  lose data with no real warning. Only triggers when `sn` is given an absolute path; relative
  filenames work correctly.
- **Command:** `sn` (`_snapshot_file`)
- **File:** `src/main/bash/functions_files_and_folders.sh:54`
  (`local -r absolute_filepath=$(pwd)/$1`) and the missing `cp` exit-code check at lines 61/68.
- **Symptom:** `sn /abs/path/file` blindly prepends `$(pwd)/`, producing a bogus path like
  `/cwd//abs/path/file`. The underlying `cp` fails (`cannot stat …`) but the function still
  prints `-> File … has been saved` and returns exit 0 — a false success.
- **Reproduction:**
  ```bash
  echo y > /tmp/abs_sample.txt
  sn /tmp/abs_sample.txt
  # -> cp: cannot stat '/cwd//tmp/abs_sample.txt'
  # -> INFO  -> File ... has been saved   (WRONG: nothing was saved, exit 0)
  ```
- **Root cause:** (a) Absolute paths are not detected before prepending `$(pwd)/`;
  (b) the `cp` result is never checked before logging success.
- **Suggested fix:** Detect `"$1" == /*` and use it as-is (mirror the pattern already used in
  `_mark_file_as_current`); check `cp`'s exit status before logging "has been saved".

---

## Install / runtime bugs

### ISSUE-3 — `return` at top level errors during `./nixlper.sh install|update`

- **Impact:** 🟡 Minor — cosmetic. Prints an error line but install/update completes normally.
  Looks alarming to users, so worth fixing, but nothing breaks.
- **File:** `src/main/bash/nixlper.sh:326`
  (`[[ "${NIXLPER_LOADED:-false}" == "true" ]] && return 0`)
- **Symptom:** Running `./nixlper.sh update` (or `install`) prints:
  `./nixlper.sh: line <N>: return: can only 'return' from a function or sourced script`.
  The install/update still completes (the error does not abort execution), so it is noise
  rather than a hard failure.
- **Root cause:** The double-load guard uses a top-level `return`, which is only valid when the
  file is *sourced* (interactive shell loading nixlper). But the same file is also *executed*
  (`./nixlper.sh update`). When the parent interactive shell has already exported
  `NIXLPER_LOADED=true`, the executed child process inherits it, reaches the top-level `return`,
  and bash rejects it. The guard is reached during execution because `main "$@"` runs at the
  bottom of the same file.
- **Reproduction:**
  ```bash
  export NIXLPER_LOADED=true
  ./nixlper.sh update     # -> return: can only `return' from a function or sourced script
  ```
- **Suggested fix:** Only apply the source-time guard when the script is actually being sourced,
  e.g. guard with `if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then ... return 0; fi`, or move the
  `NIXLPER_LOADED` guard so it never runs on the execution path that ends in `main "$@"`.

---

## Documentation drift (dual-location rule)

Per CLAUDE.md, every command in `README.md → ## Features → ### <Category>` must also appear in
the matching `src/main/help/help_<category>` file, and vice versa.

### ISSUE-4 — `olf` missing from in-shell help

- **Impact:** 🟡 Minor — documentation only. Feature works; it is just undiscoverable via
  CTRL+X+H help.
- **Files:** documented in `README.md` (Files & Folders) but absent from
  `src/main/help/help_files_folders`.
- **Symptom:** `olf` (open latest modified file) shows in the README but not in CTRL+X+H help.
- **Suggested fix:** Add an `olf` line to `help_files_folders` (e.g. under a new "Open" section):
  `olf : open the most recently modified file in the current repository`.

---

## Notes

- The command palette's inability to pass arguments to argument-taking commands is **not** a bug
  in those commands — it is a palette limitation addressed separately by the `@args` annotation
  mechanism in `functions_command_palette.sh`. Commands called directly with their arguments
  work as designed (except for the two issues above).
