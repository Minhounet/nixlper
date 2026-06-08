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

## Documentation drift (dual-location rule)

Per CLAUDE.md, every command in `README.md → ## Features → ### <Category>` must also appear in
the matching `src/main/help/help_<category>` file, and vice versa.

## Notes

- The command palette's inability to pass arguments to argument-taking commands is **not** a bug
  in those commands — it is a palette limitation addressed separately by the `@args` annotation
  mechanism in `functions_command_palette.sh`. Commands called directly with their arguments
  work as designed (except for the two issues above).
