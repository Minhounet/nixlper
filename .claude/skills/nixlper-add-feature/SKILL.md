---
name: nixlper-add-feature
description: How to add or change a nixlper bash command, alias, keybinding, config setting or module — palette annotations, the bind -x constraint, nconf wiring, unit tests, tri-location docs (help + EN + FR), palette render check. Load before writing or modifying anything under src/main/bash/ or src/main/help/.
---

# Adding or changing a nixlper feature

Work through this top to bottom. Items marked **[enforced]** are checked by
`scripts/check-doc-sync.sh` / `scripts/check-feature-completeness.sh` (CI and the pre-commit hook) — you will be
blocked if you skip them, but doing them up front is cheaper.

## 0. Before coding
Show the user a short plan (module, command name, alias/keybind, settings) and agree on it.

## 1. Where the code goes
- Related to an existing domain → add to that `src/main/bash/functions_*.sh` (clipboard → `functions_clipboard.sh`).
- New domain → new `src/main/bash/functions_<feature>.sh`. `build.sh` picks up every `function*.sh` automatically.
- Naming: `snake_case`; internal helpers prefixed `_` (e.g. `_i_log_as_error`); settings `NIXLPER_*`.
- Safety: `rm -i`, confirmation prompts, show a command before running it (e.g. `read -e -i` then `eval`).
- See `MODULES.md` for the design decisions of the module you are touching, and `INTERNALS.md` for mechanisms.

## 2. Palette annotations
```bash
# @cmd-palette
# @description: Brief description
# @category: Category name
# @keybind: CTRL+X+D        (optional)
# @alias: shortcut           (optional)
# @args: FILE PATTERN [REPL] (optional — command needs typed arguments)
# @interactive               (optional — command prompts with read)
function command_name() { ... }
```
**The `bind -x` constraint.** The palette (CTRL+X+A) runs via `bind -x find_action`; inside `bind -x` readline is
in raw mode and `read` **cannot receive keystrokes**. So `_execute_command` is hybrid:
- plain commands → executed on selection;
- `@args` → command name + trailing space placed on `READLINE_LINE` for the user to type args and press Enter;
- `@interactive` → placed on the command line as-is, user presses Enter.

The same rule applies to keybindings: a command that needs `read`/`fzf` must be bound by *inserting* it onto the
command line (`bind '"\C-x\C-l": "last_command\15"'`), never with `bind -x`. Plain commands use `bind -x`:
```bash
# in _i_load_bindings() in nixlper.sh
bind -x '"\C-x\C-y": your_function_name'   # CTRL+X then Y
```
`build.sh` keeps every `# @...` comment, so new annotation kinds need no build change. Never reintroduce a whitelist
there — a dropped annotation breaks the palette only in packaged installs.

## 3. Configurable? (ask for every feature)
If the behaviour can reasonably vary per user (timeouts, modes, on/off output, paths), add a setting:
1. Entry in `_NIXLPER_CONFIG_VARS` (`functions_config.sh`): `"NIXLPER_X|type|default|description|section"` (type: `bool`, `int`, `text`, `path`, `enum:a:b`; section: `common` or `advanced`).
2. Read it as `${NIXLPER_X:-default}` everywhere.
3. **[enforced]** Commented line in `_nconf_create_user_conf` (`functions_config.sh`).
4. **[enforced]** `:-`-guarded export in the `_i_install_system` heredoc (`nixlper.sh`).
5. **[enforced]** `:-`-guarded export in `packaging/shared/nixlper.conf` (RPM/DEB).
6. **[enforced]** Mention in the EN docs, FR docs and help (usually the feature page + `help_<category>`;
   add it to `docs/feature-configuration.md` / `docs/fr/…` and `help_config` too).

`_NIXLPER_CONFIG_VARS` is the source of truth for settings and their defaults — there is no separate table to update.

## 4. Tests
- New module → `src/test/bash/test_functions_<module>.sh`: pure bash, no framework, network/system helpers mocked,
  runnable standalone. Follow `src/test/bash/test_functions_update.sh`.
- **[enforced]** Add a named step running it to `.github/workflows/tests.yml` (CI does not auto-discover).
- Every fix/feature: exercise it by sourcing the module in a subshell — the new case, a regression case and an
  error/edge case. If something cannot be tested here (interactive terminal, missing tool), tell the user before
  committing.

## 5. Docs — tri-location rule
Every command, alias and keybinding appears in all three, updated in the same commit:
| Location | Role |
|---|---|
| `src/main/help/help_<category>` | in-shell help (CTRL+X+H), terse |
| `docs/feature-<page>.md` | GitHub Pages, English, narrative |
| `docs/fr/feature-<page>.md` | GitHub Pages, French, hand-translated |

- **[enforced]** `check-doc-sync.sh`: each `@cmd-palette` command's `@alias` and `@keybind` must literally appear in
  the help/EN/FR files derived from its slugified `@category` (`SSH` → `help_ssh`, `feature-ssh.md`). Keybinds are
  compared with formatting stripped (`CTRL+X+E` matches `[CTRL + X then E]`). When a category doesn't map to one doc
  pair (`Help`, `Utilities`, `Admin`, `Target`, some `Files & Folders`), add the command to
  `HELP_FILE_OVERRIDE` / `DOC_PAGE_OVERRIDE` at the top of the script. If neither target file exists, it's skipped.
- **[enforced]** New page → create both languages; EN links `> 🇫🇷 [Version française](fr/feature-x.md)`, FR links
  `> 🇬🇧 [English version](../feature-x.md)`.
- The scripts check facts, not prose: read the three locations yourself and make sure they describe the new behaviour.
  Prose is intentionally hand-written per audience (no generator).
- `README.md → ## Features` is a short overview linking to the Pages site — do not add command details there.

## 6. Palette render check (every new/changed `@cmd-palette` command)
```bash
source src/main/bash/functions_command_palette.sh
source src/main/bash/<module>.sh
_build_command_registry | grep "^<command>|" | while IFS= read -r l; do _format_command_for_display "$l"; done
```
Name, description and category correct; keybind column shows `[CTRL+X+?]` or `[alias: <name>]`. Blank is fine only
when the command has neither. `@args`/`@interactive` commands must be placed on the command line, not executed.

## 7. Other records
- **[enforced]** `CHANGELOG.md` → `[Unreleased]` bullet under `Added` / `Fixed` / `Changed` / `Removed`, plain English,
  bold lead-in (the release script builds the README summary from those lead-ins). Pure refactor/test branch:
  put `[no-changelog]` in a commit message instead.
- `KNOWN_ISSUES.md`: remove an entry in the commit that fixes it; add confirmed-but-unfixed defects you find.
- `INTERNALS.md`: add/update an entry when the feature uses a non-obvious shell mechanism (`PROMPT_COMMAND`,
  `bind -x`, history builtins, `trap`), keeps state across calls, can fail silently, or only makes sense as a
  lifecycle (mark → pack → clear). Skip it for features whose code is self-explanatory.
- `MODULES.md`: add an entry for a new module (settings, docs, help, tests, key design decisions).
- `CLAUDE.md`: only if a new always-relevant rule or constraint was discovered.

## 8. Bug sweep, then commit
Read every function you wrote or touched end to end: special characters in input, missing files, running twice,
older callers whose assumptions changed. Fix what you find or log it in `KNOWN_ISSUES.md`. For a second pair of eyes
on a larger change, run `/code-review`. Run `shellcheck` on the touched files if it is installed. Then `bash build.sh` and commit (`✨feat|…` / `🐛fix|…`).
