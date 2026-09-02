# Nixlper — Feature Internals

This file explains the **mechanism** behind features whose behavior is non-obvious from reading
the source. It is not a user manual — the in-shell help (`CTRL+X+H`) and `README.md` cover the
"what". This file covers the "how" and "why it works that way", for anyone extending or debugging
these features.

See `CLAUDE.md → INTERNALS.md rule` for the criteria that determine whether a feature deserves
an entry here.

---

## Debug mode — scoped tracing (`functions_debug.sh`)

### Mechanism

`ndebug` wraps a function call in `{ set -x; "$func" "$@"; } 2>&1` immediately followed by `{ set +x; } 2>/dev/null`. This scopes the `set -x` trace to a single function call rather than enabling it globally for the shell session.

**Why not global `set -x`?**  
In an interactive bash session, `set -x` traces every line executed — including readline's internal dispatches, `PROMPT_COMMAND` hooks, completion functions, and every line of `_i_load_bindings`. The result is hundreds of irrelevant lines before the function of interest even starts. Scoping with `set -x` / `set +x` around the call site produces only the trace of the target function and its callees.

**Why `{ set +x; } 2>/dev/null`?**  
`set +x` itself would appear in the trace (`+ set +x`) unless its own trace output is suppressed. Wrapping it in a subgroup and redirecting stderr to `/dev/null` discards that one line cleanly.

**Silent failure mode to watch for:** `declare -f "$func"` is used to validate the function exists before calling it. Without this check, a mistyped function name would produce no output (bash silently ignores an unknown command in some contexts) or a confusing "command not found" error that looks like a nixlper bug.

---

## Macro recording (`functions_macros.sh`)

### Mechanism

Recording uses `PROMPT_COMMAND`, a bash variable that holds a semicolon-separated list of
commands bash executes automatically after every interactive command, just before printing the
next prompt.

When `sr` / `start_recording` is called:
1. `_NIXLPER_RECORDING=true` is set and the command array `_NIXLPER_MACRO_COMMANDS=()` is cleared.
2. The hook `_i_macro_record_step` is prepended to `PROMPT_COMMAND`.

After every command the user types, bash fires `_i_macro_record_step`. It compares the current
history entry number (via `_i_get_last_hist_num`, a wrapper around `history 1 | awk '{print $1}'`)
against `_NIXLPER_LAST_HIST_NUM`. If the number didn't change, the command was excluded from
history by `HISTCONTROL` (e.g., space-prefixed command with `ignorespace`, or a duplicate with
`ignoredups`) — the step returns without capturing anything. If the number advanced, it reads the
command text via `_i_get_last_cmd` (`history 1 | sed …`), skips `sr`/`fr`, and appends to
`_NIXLPER_MACRO_COMMANDS`. `start_recording` initialises `_NIXLPER_LAST_HIST_NUM` to the current
position so pre-recording history is never captured.

When `fr` / `finalize_recording` is called:
1. `_NIXLPER_RECORDING=false` is set and the hook is removed from `PROMPT_COMMAND`.
2. The array is joined with `; ` and bound to `CTRL+X+CTRL+X` via `bind -x`.
3. The bind command is written to `NIXLPER_LAST_MACRO_BINDING_FILE` so `bind_last_macro`
   (CTRL+P+CTRL+L) can re-arm it in a new shell session.

### Why not history-file scraping?

The previous implementation injected `###START_RECORD###` / `###END_RECORD###` markers into
`~/.bash_history` via `history -s`, then extracted the commands with `sed`, and finally cleared
and reloaded the history with `history -c && history -r`. The `history -c` step wiped all
unsaved in-memory history — commands typed before `sr` that hadn't been flushed to disk were
silently lost.

### Why `_i_get_last_cmd` is a separate function

It wraps `history 1 | sed …` so unit tests can override it with a mock (`_i_get_last_cmd() { echo "ls -la"; }`) without needing a live interactive session. This is the only part of the
recording logic that can't run in a non-interactive test subshell.

### Why commands are written to a file, not interpolated into `eval`

`_prepare_binding` writes the recorded commands into a small bash file as a function body,
then `source`s it:

```bash
_nixlper_macro_replay() {
  echo 'hello world'
  grep 'foo bar' file.txt
}
bind -x '"\C-x\C-x": _nixlper_macro_replay'
```

An earlier approach used `eval "bind -x '...:( $joined )'"`. That breaks on any command containing
single quotes (e.g. `echo 'hello'`) because the quotes close the outer single-quoted string early.
It also risks executing backtick expressions during the string expansion rather than at replay
time. Writing each command as a literal line with `printf '%s\n'` and sourcing the file sidesteps
all of these quoting hazards.

### Variable expansion: recording time vs. replay time

Commands are captured from history as the user typed them — including unexpanded variables and
`$()` substitutions. When CTRL+X+CTRL+X fires, `_nixlper_macro_replay` executes, and variables
expand with their **current** values at replay time. This is generally the desired behavior
(the macro captures the template, not a snapshot of values at recording time).

### Constraint: `bind -x` and `read`

The replay binding (`CTRL+X+CTRL+X`) is installed via `bind -x`. Inside any `bind -x` callback,
bash is in readline's raw mode and `read` cannot receive keystrokes. Macros therefore only work
correctly for non-interactive command sequences. A macro that internally calls `read` (prompts
the user) will silently fail or block during replay.

---

## Navigation alias namespace (`functions_navigation.sh`)

### Mechanism

Every call to `navigate` (tree or flat mode), `fan`, or `fag` generates numbered shell aliases
in the current session:

| Alias | Action |
|---|---|
| `vN` | Open file N in `$NIXLPER_EDITOR` |
| `nN` | Navigate into folder N |
| `dN` | Delete file N (`rm -i`) |
| `tcN` | Copy file N to target staging |
| `tmN` | Mark file N for target pack |
| `cdfN` | `cd` to folder containing file N then navigate |

CTRL+X+1 through CTRL+X+9 are also bound (via `bind -x`) to navigate into folders 1–9.

### The stale-alias problem and the fix

Without cleanup, aliases from a previous call persist. If a directory had 8 items (`v1`–`v8`)
and you navigate to one with 3 (`v1`–`v3`), aliases `v4`–`v8` silently remain pointing at the
old paths. Typing `v5` takes you to a stale location with no warning.

The fix tracks two globals, `_NIXLPER_LAST_FILE_COUNT` and `_NIXLPER_LAST_FOLDER_COUNT`, updated
at the end of every navigate call. At the **start** of the next call, `_i_cleanup_nav_aliases`
unaliases every alias up to those counts and removes the CTRL+X+1–9 bindings.

### `fan` / `fag` share the `vN` namespace with `navigate`

All three commands write to the same `v*`/`n*` alias set. Calling `navigate` after `fan` clears
the fan results, and vice versa. This is intentional — there is only one "current navigation
context" at any time.

### `fag` does not create `nN` aliases

`_grep_and_navigate` only creates `vN` aliases (open file at matching line). `_NIXLPER_LAST_FOLDER_COUNT` is left at 0 after a `fag` call, so `_i_cleanup_nav_aliases` does not
try to unalias `n*` entries that were never created.

---

## Command palette dispatch (`functions_command_palette.sh`)

### The `bind -x` constraint

The palette (`CTRL+X+A`) is itself bound via `bind -x find_action`. Inside a `bind -x` callback,
readline's raw mode is active and `read` cannot receive keystrokes. This means the palette
cannot directly execute commands that prompt for input or require typed arguments.

### Hybrid dispatch: execute vs. place-on-command-line

`_execute_command` handles this in two ways depending on the command's annotations:

- **Plain commands** (no `@args`, no `@interactive`): executed immediately by setting
  `READLINE_LINE` to the command and simulating Enter via `READLINE_POINT`.
- **`@args` commands**: placed on the command line (with a trailing space) so the user can type
  arguments and press Enter in normal shell mode where `read` works.
- **`@interactive` commands**: placed on the command line as-is so the user presses Enter and
  the command runs interactively.

Both `@args` and `@interactive` commands still work normally when invoked via their own
aliases/keybindings — the annotation only changes palette dispatch behavior.

### `@alias:` is documentation, not registration

`@alias: name` only tells the parser what short name to *display* in the palette (and, via
`_execute_command`, what to `eval` when a plain command is selected). It does **not** create the
shell alias itself — that alias must still be added explicitly in `nixlper.sh`'s `ALIASES`
section (`alias name=function_name`). Annotating a function with `@alias: foo` but forgetting
the matching `alias foo=...` line is a silent failure: the palette entry looks correct and
`_function_name` still works when called directly, but typing `foo` on the command line (the
form every doc page advertises) fails with `command not found`. `logtail` shipped this way for
one release before the missing `alias logtail=_logtail` was added — when adding a new
`@alias`-annotated command, always add its `alias` line in `nixlper.sh` in the same commit.

---

## Target staging lifecycle (`functions_target.sh`)

### State

The target folder (default `/tmp/nixlper_target`, overridable via `tsd`) holds files and a hidden
`.marks` file listing paths queued for batch packing.

### Lifecycle

```
tc FILE       → copies FILE into the target folder immediately (no mark)
tm FILE       → appends FILE path to .marks (does not copy yet)
tml           → lists .marks contents
tum           → interactive: pick a file to remove from .marks
tcm           → empties .marks without copying
tp            → reads .marks, packs all listed files into a .tgz, then clears .marks
tclean        → deletes all files in the target folder (confirmation required)
```

`tc` and `tm` are independent paths — a file can be directly copied AND also marked for packing
in the same session.

### Why `/tmp` as the default

The target folder is deliberately world-readable so files can be transferred between users on the
same machine via `/tmp`. `tc` and `tp` both `chmod 644` the files they place there.

---

## Update detection (`functions_update.sh`)

### Channels

| Channel | Compares |
|---|---|
| `stable` | Installed `VERSION:` field vs. GitHub `releases/latest` tag |
| `edge` | Installed `COMMIT:` SHA vs. `target_commitish` of the `edge` pre-release |
| `off` | No network check at startup |

`build.sh` writes both fields into the `version` file at build time.

### Throttling

Startup checks are gated by `NIXLPER_UPDATE_CACHE_FILE` (default interval: 86400 s). The `nu` /
`CTRL+X+W` command bypasses the cache and always fetches. This prevents every new shell from
making a network request.

### Offline guard

Before any network call, `_i_is_online` sends a time-boxed `curl` probe. If the machine is
offline, the check is skipped silently — no error, no hang at login.

### Edge pre-release

CI publishes a rolling `edge` pre-release via `.github/workflows/publish_edge_on_push.yml` on
every push to `main` **except release commits** (messages starting with `🔖release|` are
skipped). Skipping release commits prevents two problems: (1) a race where the `vX.Y.Z` tag
created by `create_release_on_tag.yml` is visible to the edge build's `git describe` call,
causing the edge artifact to embed `VERSION: vX.Y.Z` and become indistinguishable from the
stable release; (2) the edge release pointing to the same commit as stable, which makes
the edge update check loop (see below).

The release creation workflow (`create_release_on_tag.yml`) excludes the `edge` tag via a
`!edge` tag filter so it is never promoted to a stable release.

### Why the edge update check uses the pre-release SHA, not `main` HEAD

`_i_remote_edge_release_commit` fetches `target_commitish` from the `edge` GitHub pre-release
(the full SHA passed to `--target` when CI published the build) instead of the raw HEAD of
`main`. This prevents a false-positive loop: if the edge workflow is skipped on a release
commit, the latest commit on `main` is the release SHA but the edge pre-release is still at
the prior commit. Comparing against `main` HEAD would always show "update available" even
after updating, because the user installs the pre-release SHA (old) which still differs from
the main HEAD (release). Comparing against the pre-release SHA gives the correct answer:
"up to date" when the user has what CI actually published.

---

## Recent directories (`functions_recent_dirs.sh`)

### Mechanism

Tracking uses `PROMPT_COMMAND` — bash fires this after every interactive command, just before
printing the next prompt. `_i_recent_dirs_init` prepends `_i_recent_dirs_track` to it at startup
(guarded so it is never added twice).

On each prompt, `_i_recent_dirs_track`:
1. Reads `$PWD`. Skips `$HOME` and `/` (too generic).
2. Resolves the history file (`NIXLPER_RECENT_DIRS_FILE`, default `~/.local/share/nixlper/recent_dirs`).
3. Writes a new version of the file: current dir on top, all prior occurrences of current dir
   removed (`grep -vxF`), trimmed to `NIXLPER_RECENT_DIRS_MAX` entries via `head -n`.
   Uses a `mktemp` temp file + `mv` to make the write atomic — a partial write cannot corrupt
   the history file.

### Silent failure mode

If `NIXLPER_RECENT_DIRS_MAX` is set to a non-integer, `head -n` will error and the temp file
will remain empty, causing the next `mv` to truncate the history file. The value should always
be a positive integer; `nconf` enforces the `int` type when editing via the interactive editor.

### Why `grep -vxF` (not `grep -v`)

`-x` matches the whole line (exact path), `-F` treats the pattern as a fixed string (not a
regex). Without `-F`, a path like `/opt/foo.bar` would be treated as a regex where `.` matches
any character, potentially removing unrelated paths that happen to match. Without `-x`, a path
`/home/user` would also remove `/home/user/projects` from the list.

### Why home and root are excluded

These directories are visited implicitly by many commands (shell startup, `cd` with no args,
`sudo -i`, etc.) — they would dominate the list and push actually useful recent dirs off.
Exclusion is checked in `_i_recent_dirs_track`; `recent_dirs` additionally skips any entry
whose directory no longer exists on disk.

### Fuzzy picker vs. numbered fallback

`recent_dirs` dispatches to one of two pickers rather than implementing the picker itself:
`_i_recent_dirs_fuzzy_pick` (fzf) or `_i_recent_dirs_numbered_pick` (plain `read`). The
dispatch condition — `NIXLPER_RECENT_DIRS_FUZZY` not `false` **and** `fzf` on `$PATH` — is
checked on every call, not cached, so installing/removing `fzf` or flipping the setting via
`nconf` takes effect on the very next `rd` with no re-source needed.

Both pickers read the candidate list through the shared `_i_recent_dirs_list` helper, which
filters out entries whose directory no longer exists (`[[ -d "$line" ]]`) — this is the same
"skip removed dirs" behavior the old single-function implementation had, just factored out so
both pickers agree on what "recent" means. Each picker still re-checks `[[ -d "$target" ]]`
right before `cd`, because a directory can be removed in the (short) window between listing it
and the user selecting it.

### Silent failure mode: fzf's empty result is ambiguous

`fzf` prints nothing to stdout both when the user presses `Esc` and when they type a filter
that matches nothing and press `Enter` (no `--print-query`, so we can't tell those apart from
the command substitution alone). `_i_recent_dirs_fuzzy_pick` treats both the same way — "Cancelled." — since neither has a directory to jump to; the only other exit path is a directory that got removed between listing and selection.

### Number-jump and fuzzy-filter in the same picker

`rd` supports two input styles at once inside the same `fzf` prompt: typing digits jumps to
that numbered entry (matching the old numbered picker's muscle memory), typing letters
fuzzy-filters by path (IntelliJ-style). This is not two code paths — it is a single trick in
`_i_recent_dirs_indexed_list`: each candidate is prefixed with its 1-based index before being
handed to `fzf` (`"N  /path"`, two spaces, no `--nth` restriction — the whole line is
searchable). `fzf`'s default scoring (`fzf --filter` was used to verify this empirically, see
below) strongly favors a match at the very start of the line, so a query of `3` scores the line
starting `3  ` far above any line whose path merely *contains* a `3` somewhere in the middle —
verified directly:

```bash
$ printf '1  /home/x/alpha\n2  /home/x/beta\n3  /home/x/gamma\n4  /home/x/proj3\n' | fzf --filter='3'
3  /home/x/gamma
4  /home/x/proj3
```

Entry `3` (the number match) ranks first even though entry `4`'s path also contains a literal
`3`. This only holds because the index prefix starts at column 0 — right-padding it (e.g.
`"%2d) %s"`, as the numbered picker does for visual alignment) would push single-digit indices
off column 0 and weaken this bonus, so `_i_recent_dirs_indexed_list` deliberately uses an
unpadded `"%d  %s"` instead, at the cost of columns not lining up visually for 10+ entries.

`_i_recent_dirs_fuzzy_pick` strips the `"N  "` prefix back off the selected line with
`${selected#*  }` (shortest-match removal up to the first `"  "`). This is safe even if a path
itself contains a double space later on, because a real directory path always starts with `/`,
never a digit — so the *first* `"  "` encountered in the full line is always the separator we
inserted, never one occurring inside the path.

---

## Bookmarks (`functions_bookmarks.sh`)

### Storage doubles as executable aliases

Bookmarks are not stored as plain data — each line in `NIXLPER_BOOKMARKS_FILE` is a literal
bash `alias` statement: `alias NAME='cd PATH && echo "INFO: ..."'`. This is deliberate: typing
the bookmark's name at any prompt jumps to it directly, with zero picker involved, because it
*is* a real alias sourced into the shell. Every other bookmark operation — display, jump,
delete — has to parse this executable-statement format back out rather than reading structured
data, which is why the extraction regexes below matter.

### Same number-jump/fuzzy-filter trick as `rd`, adapted for two fields

`bookmark_dirs` (`bd` / `CTRL+X+D`) reuses the exact hybrid trick documented above for
`recent_dirs`: `_i_bookmarks_fuzzy_pick` feeds `fzf` lines prefixed with a 1-based index
(`"N  alias  (path)"`), so a digit query ranks that index at the top while a letter query
fuzzy-filters by alias name or path text — see the `recent_dirs` section for the empirical
`fzf --filter` evidence behind why this works.

The extraction differs from `rd`, though: a bookmark line carries *two* fields (alias, path)
instead of one bare path, and the path can itself contain spaces. Reparsing the path back out
of the selected fzf line (as `rd` does with a prefix-strip) would be fragile here, so
`_i_bookmarks_fuzzy_pick` instead extracts only the leading index (`${selected%% *}`, everything
before the first space — always a clean integer) and uses it to index into `names`/`paths`
arrays built *before* the line was ever handed to `fzf`. The display line is therefore
write-only from the picker's perspective: `fzf` only needs it to rank and return the original
line back verbatim, never to be parsed for data.

### Both pickers re-derive their candidate list independently

Like `_i_recent_dirs_fuzzy_pick`/`_i_recent_dirs_numbered_pick`, `_i_bookmarks_fuzzy_pick` and
`_i_bookmarks_numbered_pick` each call `_i_bookmarks_valid_entries` themselves rather than
sharing arrays built by the caller. This avoids `local -n` namerefs (bash 4.3+; the RPM spec
only requires bash ≥ 4.0) at the cost of re-parsing the (small) bookmarks file twice per `bd`
call — a deliberate, negligible trade for wider bash compatibility.

### Why the greedy path capture matters (and where it still doesn't reach)

`_i_bookmarks_valid_entries`'s regex — `^alias[[:space:]]+([A-Za-z0-9_]+)='cd[[:space:]]+(.*)[[:space:]]&&` —
captures the path with a **greedy** `(.*)`, which backtracks to the *rightmost* `" && "` in the
line. This correctly extracts a path containing spaces (verified: `cd /home/user/my projects/dir && echo ...`
extracts `/home/user/my projects/dir` intact). The legacy display formatter,
`SED_PATTERN_EXTRACT_ALIAS` in `_display_existing_bookmarks`, used to capture the path with
`\S+` (non-whitespace only) — for a spacey path that pattern fails to match the line at all, so
`sed`'s `s///` left the line completely unformatted (the raw `alias NAME='cd ...'` text printed
verbatim instead of the intended `"path (alias)"`). It now uses the same greedy `(.*)` capture
as the picker, for the same reason.

This greedy-capture fix only reaches the **read** side (listing and jumping). The **write**
side — `_i_bookmark_directory`, which builds the alias line at bookmark-creation time — still
interpolates the path unquoted (`cd $bookmarked_dir && ...`), so a bookmark whose path contains
spaces still breaks when its alias is typed directly (word-splitting turns `cd /a/b c` into `cd`
with two arguments). `bookmark_dirs`/`bd` sidesteps this entirely, because it never re-invokes
the stored alias — it `cd`s to the path pulled from the parsed `paths` array with normal bash
quoting (`cd "$target"`), which handles spaces correctly regardless of how the alias itself was
written. See `KNOWN_ISSUES.md` for the still-open direct-alias-invocation case.

### Silent failure mode: `bind -x` cannot run this picker

`bookmark_dirs` calls `read` (numbered fallback) or `fzf` (fuzzy path) — both require the normal
readline/terminal state, which is unavailable inside a `bind -x` callback (raw mode; see the
`@interactive` constraint in `CLAUDE.md`). `CTRL+X+D` used to bind `_display_existing_bookmarks`
directly via `bind -x`, which was safe because that function only prints. Now that `CTRL+X+D`
resolves to the interactive `bookmark_dirs`, the binding had to move to the same
insert-onto-the-command-line mechanism used by `rd` and `sc`:
`bind '"\C-x\C-d": "bookmark_dirs\15"'` (types the command and a simulated Enter, then executes
it in the normal shell) instead of `bind -x '"\C-x\C-d": bookmark_dirs'`. Any future change that
makes a `bind -x`-bound command call `read` or `fzf` needs the same fix, or it will silently do
nothing when triggered by its keybinding (it still works when invoked by typing its name/alias
directly, since that never goes through `bind -x` in the first place).
