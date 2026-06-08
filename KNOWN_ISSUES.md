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

## Documentation drift (dual-location rule)

Per CLAUDE.md, every command in `README.md → ## Features → ### <Category>` must also appear in
the matching `src/main/help/help_<category>` file, and vice versa.

## Notes

- The command palette's inability to pass arguments to argument-taking commands is **not** a bug
  in those commands — it is a palette limitation addressed separately by the `@args` annotation
  mechanism in `functions_command_palette.sh`. Commands called directly with their arguments
  work as designed (except for the two issues above).
