# Modules — design notes

Per-module map: where each module's settings, docs, help and tests live, plus the design decisions that are not
obvious from the code. Read the entry for the module you are about to change. Mechanisms (how something works
under the hood) belong in [`INTERNALS.md`](INTERNALS.md); confirmed bugs in [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

Add an entry when you create a module or make a design decision a future developer would otherwise re-litigate.
Conventions that hold for every module (file names `functions_<x>.sh` → `test_functions_<x>.sh`, help in
`src/main/help/help_<category>`, docs in `docs/feature-<page>.md` + `docs/fr/`) are not repeated here.

- **`functions_processes.sh`** — `ik` (interactive kill) and `pc` (port quick-check). `ik` with no
  flag opens a single `fzf` picker whose rows join `ps` output with the TCP listening-socket map
  (`ss -tlnp`, falling back to `netstat -tlnp`), so one query filters on command name, PID **and**
  port at once — no port/pattern mode question. `--multi` (TAB) marks one process, `CTRL-A` marks every row the filter shows
  (group kill), and `ik --all PATTERN` is the picker-less group kill (command-line substring, excludes the
  caller's process subtree); the marked list is always confirmed before `kill -9`. Deliberately has **no** `N ` index column, unlike `rd`/`bd`/`lc`:
  digits here must mean port or PID (see INTERNALS.md). The legacy `ik --port` / `ik --pattern` paths
  are untouched and remain the fallback when `fzf` is absent. Configurable via `nconf`:
  `NIXLPER_KILL_FUZZY` (bool, default `true`), `NIXLPER_KILL_EXACT` (bool, default `false`, same as `ik --exact`:
  `fzf --exact` strict substring matching instead of fuzzy) and `NIXLPER_PORT_CHECK_SHOW_CMDLINE` (bool, default
  `true`). Docs: `docs/feature-processes.md` / `docs/fr/feature-processes.md`, help:
  `src/main/help/help_processes`, tests: `src/test/bash/test_functions_processes.sh`.

- **`rp` in `functions_files_and_folders.sh`** — `rp FILE` (`@args`/`@interactive`, alias wired in `nixlper.sh`):
  interactive search & replace using vi `:s` syntax executed through `ex` (requires vim; no sed). Prompts for
  search/replace/range/flags, previews changed lines, applies after confirmation, snapshots first so `re` undoes it.
  Configurable via `nconf`: `NIXLPER_REPLACE_SNAPSHOT` (bool, default `true`). Bare `|` is rejected (ex command
  injection guard, see INTERNALS.md). Docs: `docs/feature-files-folders.md` / `docs/fr/feature-files-folders.md`, help:
  `src/main/help/help_files_folders`, tests: `src/test/bash/test_functions_replace.sh`.

- **`functions_logtail.sh`** — `logtail FILE PATTERN` (`@args` command, no keybind — see the
  `bind -x` constraint in the `nixlper-add-feature` skill). Wraps `tail -F FILE | grep --color=always -E PATTERN`; `-F`
  (not `-f`) so it survives log rotation. Configurable via `nconf`: `NIXLPER_LOGTAIL_IGNORE_CASE`
  (bool, default `false`) and `NIXLPER_LOGTAIL_LINES` (int, default `10`, initial lines shown
  before following). Docs: `docs/feature-logs.md` / `docs/fr/feature-logs.md`, help:
  `src/main/help/help_logs`, tests: `src/test/bash/test_functions_logtail.sh`.

- **`functions_last_command.sh`** — `last_command` / `lc` / `CTRL+X+L`: re-run a previous shell
  command. Reads bash's own `history` builtin (no separate tracking file, unlike recent dirs),
  deduplicated and capped at `NIXLPER_LAST_COMMAND_MAX` (default `50`). Same hybrid
  fzf-incremental/numbered picker as `rd` (recent dirs) and `bd` (bookmarks), toggled via
  `NIXLPER_LAST_COMMAND_FUZZY` (default `true`). Bound like `rd`/`sc` — inserted onto the command
  line (`bind '"\C-x\C-l": "last_command\15"'`), not `bind -x`, since it needs `read`/`fzf`. The
  selected command is never run blindly: it is preloaded onto an editable `read -e -i` prompt
  (safety pattern — display before execution) before `eval`. Docs: `docs/feature-history.md` /
  `docs/fr/feature-history.md`, help: `src/main/help/help_history`, tests:
  `src/test/bash/test_functions_last_command.sh`.

- **`functions_broadcast.sh`** — `bset`/`bshow`/`bclear`: admin login notice, independent from
  nixlper's own welcome message. `bset` is `@interactive` (prompts for message text, then an
  optional expiry in days — blank means persistent until `bclear`). Storage: a single file
  (`NIXLPER_BROADCAST_MESSAGE_FILE`, default `$NIXLPER_INSTALL_DIR/broadcast_message` manual /
  `/etc/nixlper/broadcast_message` RPM/DEB) plus an optional `<file>.expires` sidecar holding an
  epoch timestamp. Expiry is checked lazily at login (`_i_broadcast_active`, called from
  `_i_init` via `_i_load_broadcast_message`) — an expired notice is deleted the next time
  anyone logs in, not by a background timer. Configurable via `nconf`:
  `NIXLPER_DISABLE_BROADCAST_MESSAGE` (bool, default `false`) and
  `NIXLPER_BROADCAST_MESSAGE_FILE`. Docs: `docs/feature-admin-notice.md` /
  `docs/fr/feature-admin-notice.md`, help: `src/main/help/help_admin`, tests:
  `src/test/bash/test_functions_broadcast.sh`.

- **`src/main/powershell/Nixlper/`** — PowerShell port (preview), packaged separately by `build-ps.sh`. Constraints
  and layout: the `nixlper-powershell` skill (`.claude/skills/nixlper-powershell/SKILL.md`); mechanism:
  `INTERNALS.md` → "PowerShell port".
