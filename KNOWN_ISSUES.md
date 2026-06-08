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

---

## Documentation drift (dual-location rule)

Per CLAUDE.md, every command in `README.md → ## Features → ### <Category>` must also appear in
the matching `src/main/help/help_<category>` file, and vice versa.

## Notes

- The command palette's inability to pass arguments to argument-taking commands is **not** a bug
  in those commands — it is a palette limitation addressed separately by the `@args` annotation
  mechanism in `functions_command_palette.sh`. Commands called directly with their arguments
  work as designed (except for the two issues above).
