---
name: nixlper-powershell
description: Work on the nixlper PowerShell port (src/main/powershell/Nixlper, build-ps.sh, src/test/powershell) — module layout, Windows PowerShell 5.1 and pure-ASCII constraints, bash-compat aliases, packaging as a zip, running the pwsh tests in a cloud session. Load before touching any .ps1/.psd1/.psm1 file or build-ps.sh.
---

# nixlper PowerShell port (preview)

## Layout
`src/main/powershell/Nixlper/` is a module: `Nixlper.psd1` + `Nixlper.psm1`, which dot-sources `Private/*.ps1` and
`Public/*.ps1`.
- `Public/BashCompat.ps1` — `grep`, `head`, `tail`, `wc`, `touch`, `which`, `export`, `ls`, `rm`, `cp`, `mv` as
  `Invoke-Nixlper<Cmd>` functions, reached through global aliases.
- `Public/Bookmarks.ps1` — `bd`/`bm`, same bookmark file format as bash.
- `Public/CommandPalette.ps1` — `fa`, parses the same `# @cmd-palette` annotations from the module's own `Public/*.ps1`.

Mechanism details: `INTERNALS.md` → "PowerShell port".

## Hard constraints
- Sources are **pure ASCII** (Windows PowerShell 5.1 reads BOM-less files as ANSI; `build-ps.sh` fails on non-ASCII).
- **Windows PowerShell 5.1-compatible**: no `??`, no ternary, no `&&`/`||` pipeline chains.
- Never call a bare `ls`/`rm`/`cp`/`mv` inside the module — they may be our own aliases. Use module-qualified cmdlets,
  e.g. `Microsoft.PowerShell.Management\Remove-Item`.

## Settings — environment variables only (no `nconf`, that's bash)
| Variable | Default | Meaning |
|---|---|---|
| `NIXLPER_BASH_COMPAT` | `auto` | `auto` = on for Windows only; real executables on `PATH` always win. `true`/`false` force it. |
| `NIXLPER_PS_KEYBINDINGS` | `true` | PSReadLine key handlers |
| `NIXLPER_BOOKMARKS_FILE`, `NIXLPER_BOOKMARKS_FUZZY` | shared with bash | |

## Packaging
Not part of `build.sh`, the tar, RPM or DEB. `build-ps.sh` zips the module to
`build/distributions/nixlper-powershell-<tag|sha>.zip`: one top-level `Nixlper/` folder plus a `version` file. A plain
`vX.Y.Z` tag is stamped into the packaged `ModuleVersion` (the source manifest stays `0.1.0`). Unlike `build.sh` it
never wipes `build/distributions`, so `create_release_on_tag.yml` runs it after the tar/RPM/DEB builds and uploads the
zip; `tests.yml` builds it and imports it by name on every push.

Users install with `Unblock-File` (Windows only) + `Expand-Archive` into the first `$env:PSModulePath` entry (the user
modules folder on every OS — `(Split-Path $PROFILE)\Modules` is only right on Windows), or `Import-Module` from a clone.
PowerShell Gallery publishing is future work.

## Tests and docs
- `pwsh -NoProfile -File src/test/powershell/Test-Nixlper.ps1` — pure pwsh, no Pester; wired into `tests.yml`.
- No `pwsh` in a cloud session? Download the Linux tarball from the PowerShell GitHub releases into the scratchpad and
  run it from there.
- Docs: `docs/feature-powershell.md`, `docs/fr/feature-powershell.md`, help `src/main/help/help_powershell`.
  `check-doc-sync.sh` only scans `src/main/bash`, so keep these tables in sync **by hand**.
- CHANGELOG `[Unreleased]` bullet as for any feature.
