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

CTRL+X+1 through CTRL+X+9 are also bound (via `bind -x`) inside `_i_navigate_tree`/`_i_navigate_flat` to navigate into folders 1–9. These inner `bind -x` calls are made as regular commands (not inside a `bind -x` callback), so they always work.

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

### Fuzzy picker index is independent from alias numbers

`_i_navigate_fuzzy_pick` (called by `navigate` when `fzf` is installed and `NIXLPER_NAVIGATE_FUZZY` is true)
lists entries using its own `find` query (folders first alphabetically, then files alphabetically), with its
own 1-based index. This ordering does **not** match the alias numbering produced by `_i_navigate_tree` (tree order)
or `_i_navigate_flat` (files first, then folders, in find's unspecified order). A user who sees "3  [F] build.sh"
in the fuzzy picker and types `v3` in the shell may get a different file.

This is intentional: the two systems are independent. The fuzzy picker is a one-shot navigator — it `cd`s or
opens immediately. The `vN`/`nN` aliases are for keyboard-only navigation without fzf. Mixing both in a single
interaction is not a supported workflow. The ordering divergence is not fixable without sharing mutable state
between the listing and picker (a stale-alias-class risk), and the benefit is low since fzf users do not type
numbered aliases after using fzf.

### Listing is buffered to a temp file so it is only shown on ESC

`navigate` redirects the listing function's stdout to a `mktemp` file while running it in the
current shell (so aliases and `bind` calls still take effect). If `_i_navigate_fuzzy_pick`
returns 0 (selection made), the temp file is silently deleted. If it returns 1 (ESC or empty
directory), `navigate` `cat`s the temp file so the user sees the numbered shortcuts. This avoids
showing the listing unless the user explicitly asks for it (by pressing ESC), giving a clean
fzf-first experience while preserving the full alias-based workflow as a fallback.

Using a subshell (`$(...)`) to capture the listing was not an option because aliases and `bind`
commands set inside a subshell do not propagate to the parent shell.

### Silent failure mode: `bind -x` cannot run the fuzzy picker

`_i_navigate_fuzzy_pick` calls `fzf` (or `read` in the numbered fallback), which require the normal readline/
terminal state unavailable inside a `bind -x` callback. The `CTRL+X+N` binding was therefore changed from
`bind -x '"\C-x\C-n": navigate'` to `bind '"\C-x\C-n": "navigate\15"'` (inserts the command text and a
simulated Enter, running it as a normal shell command). This matches the pattern used by `rd`/`bd`/`lc`.
See the bookmarks section below for the full rationale.

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

The mirror-image mistake also happens: a real `alias foo=...` line exists but the `@cmd-palette`
block has no matching `@alias: foo`. The parser then falls back to the bare function name as the
registry's identifier, which nothing in the docs actually mentions (they document `foo`, not the
internal function). `recent_dirs`/`last_command` shipped this way — `rd`/`lc` worked fine as
shell aliases, but the registry never captured them, so `scripts/check-doc-sync.sh` (below) could
not verify they were documented. Fixed by adding the missing `@alias:` lines.

---

## Tri-location doc sync check (`scripts/check-doc-sync.sh`)

### What it checks

For every command the `_build_command_registry` parser (above) extracts, the script derives
which `help_<slug>` and `feature-<slug>.md`/`fr/feature-<slug>.md` files are supposed to mention
it, then greps each existing one for the command's `@alias` (only when declared — see above) and
its `@keybind`. It does not check prose, ordering, or whether the description text matches; only
that the fact "this alias/keybind exists" appears somewhere in each doc file that exists for it.

### Why a slug isn't always `@category` lowercased

The default slug is the `@category` value lowercased, with `&` dropped and spaces collapsed to
`_` (help) or `-` (docs). This holds for most categories (`SSH` → `help_ssh`/`feature-ssh.md`),
but several categories are shared by doc pages that have nothing to do with each other:
`Help` covers `functions_jokes.sh` and `functions_tips.sh`, which have unrelated doc pages;
`Utilities` covers `functions_config.sh`, `functions_syshealth.sh`, and several `nixlper.sh`
keybindings that have no doc page of their own. Other categories map to a single doc pair, but
the pair's name doesn't match the category word (`Admin` → `feature-admin-notice.md`, `Target` →
`feature-target-staging.md`). These are listed in the `HELP_FILE_OVERRIDE`/`DOC_PAGE_OVERRIDE`
associative arrays at the top of the script, keyed by the command/alias name the registry emits
(not by category, since a whole category can't be redirected as a unit — see `Help`/`Utilities`
above). A command with no override and no matching `help_<slug>`/`feature-<slug>.md` file at all
is silently skipped, not flagged: the script only enforces docs that are supposed to exist.

### Keybind normalization

Keybinds are written inconsistently across hand-written docs (`CTRL+X+E` in the annotation vs.
`[CTRL + X then E]` or `CTRL + X THEN U` in prose). Both the target file's full text and the
keybind token are stripped down to bare uppercase alphanumerics before comparison
(`_normalize_keybind`), so formatting differences never register as drift — only an
actually-missing keybind does.

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

---

## Interactive kill picker (`functions_processes.sh`)

### Mechanism

`ik` builds one flat list where each row carries everything a query could reasonably target:

```
PID     PORTS           USER       COMMAND
1234    :8080,:9090     user       java -jar myapp.jar
```

That row is a **join** of two independent sources, done in `_i_kill_candidates`:

1. `ps -eo pid=,user=,args=` — every process.
2. `_i_kill_ports_map` — `pid port` pairs for every TCP listening socket, from `ss -tlnp` or
   (fallback) `netstat -tlnp`, parsed by `_i_kill_parse_ss_ports` / `_i_kill_parse_netstat_ports`.

The join is an associative array keyed by PID, so the ports end up on the same *line* as the
command name. That colocation is the entire feature: `fzf` matches against whole lines, so a
query of `8080` and a query of `java` hit the same list without the user declaring which axis
they are searching on. The old flow had to ask "port or pattern?" precisely because the two
lived in separate code paths.

A PID can appear several times in the socket map — once per bound address. `0.0.0.0:8080` and
`[::]:8080` are two sockets, one service, so the accumulator checks membership before appending
(`",${ports}," != *",:${port},"*`) or the column would read `:8080,:8080`.

Parsing is deliberately split from collection so it can be unit-tested with canned tool output:
`src/test/bash/test_functions_processes.sh` pipes fixture text through the parsers and mocks
`ps` / `_i_kill_ports_map`, so CI needs neither `ss`, `netstat`, nor a live process.

### Why there is no index column here

`rd`, `bd` and `lc` prefix each row with `N  ` so digits mean "jump to entry N" (see *Recent
directories → Number-jump and fuzzy-filter in the same picker*). `ik` deliberately does **not**:
here digits must mean *port* or *PID*, which is the whole point. An index column would compete
with the port for every numeric query — typing `8080` would rank row 8080 (and rows containing
those digits in their index) against the process actually holding the port.

The PID takes the index's structural role instead: it is the first field, so the selected line
maps back to a target with `${line%% *}` — no parallel arrays needed, unlike `_i_bookmarks_fuzzy_pick`.

### Silent failure mode: a pipeline makes fzf list itself

The candidate list is built into a variable **before** `fzf` is invoked:

```bash
candidates=$(_i_kill_candidates)
selected=$(printf '%s\n' "${candidates}" | fzf "${fzf_args[@]}")
```

The obvious `_i_kill_candidates | fzf` is wrong: both sides of a pipeline start concurrently, so
`ps` runs while `fzf` is already alive and `fzf` appears in its own kill list. Nothing errors —
you just get a puzzling extra row, and killing it takes the picker down with it.

For the same reason `_i_kill_candidates` filters out the `ps` invocation it just spawned. The
match is against the exact command line (`ps -eo ${_NIXLPER_KILL_PS_FORMAT}`), not a broad
`^ps ` pattern, so a real `ps` the user *does* want to kill still shows up. This is the same
concern as the historical `grep -v grep` in `_i_kill_by_pattern`.

The caller's own shell (`$$`) is filtered out on the same pass. `$$` is the parent shell's PID
even inside the command substitution, so this works without any extra plumbing.

### Why the legacy flags stay

`ik --port` / `ik --pattern` bypass the picker entirely and keep their original code paths.
Besides backward compatibility, `pc` prints `ik --port N` as its suggested action, and the
port/pattern prompt remains the fallback when `fzf` is absent or `NIXLPER_KILL_FUZZY=false` —
so that flow cannot be deleted, only demoted. A bare non-flag argument (`ik java`), which used
to be rejected as an invalid parameter, now seeds the picker's initial query.

---

## PowerShell port (`src/main/powershell/Nixlper`)

### Why global aliases, not exported functions

On Windows, `ls`, `rm`, `cp` and `mv` already exist as built-in **AllScope aliases**, and in PowerShell's command
lookup an alias always wins over a function of the same name. A module that simply exported a function called `ls`
would never be reached. So the bash-style commands are implemented as `Invoke-Nixlper<Cmd>` functions, and
`Register-NixlperBashCompat` (in `Nixlper.psm1`) points the bash names at them with
`Set-Alias -Scope Global -Force`. The previous alias targets are remembered and restored by the module's `OnRemove`
handler, so `Remove-Module Nixlper` puts PowerShell back exactly as it was.

In `auto` mode (the default) the layer only runs on Windows, and skips any name that exists as a real executable on
`PATH`: on Linux/macOS, or with Git for Windows' `usr/bin` on `PATH`, the genuine `grep` must not be shadowed by an
emulation.

### Bash flags vs PowerShell parameters

The compat functions are *simple functions* (no `param()` block), so PowerShell hands every argument over untouched in
`$args`: `-rn` arrives as the string `"-rn"`. `Test-NixlperBashFlags` checks, case-sensitively, that every option-like
argument is a cluster of that command's bash letters (`rRfiv` for `rm`). If any is not (`-Recurse`, `-Force`,
`-Destination`), the call is PowerShell-style and is forwarded as `& Remove-Item @args`. Splatting `$args` keeps
`-Force` a named parameter rather than a string, so the forwarded call behaves as if the alias still pointed at the
cmdlet. Without this, any existing script or module that calls `rm -Recurse` in the session would break once nixlper
is loaded (a **silent failure mode** for code the user did not write). Pipeline input is forwarded the same way
(`$input | Remove-Item @args`). In bash mode, piped `FileSystemInfo` objects become leading path arguments, so
`Get-ChildItem *.tmp | rm` keeps working.

PowerShell's parser consumes a bare `--` before the function runs, so `grep -- -x` cannot be detected. `grep -e -x` is
the documented workaround.

### grep: BRE translation and exit codes

`ConvertTo-NixlperRegex` walks the pattern once. In basic mode (no `-E`), `\|`, `\(`, `\)`, `\{`, `\}`, `\+` and `\?`
become operators and their bare forms become literals (GNU BRE rules). POSIX classes (`[[:digit:]]`) and `\<`/`\>` are
translated in both modes. Inside a bracket expression backslash is literal, as in POSIX. The result is compiled once
as a .NET `Regex`. `$global:LASTEXITCODE` is set to 0/1/2 like GNU grep, so `grep -q x f; if ($LASTEXITCODE -eq 0)`
works in scripts.

### Keybindings: submit a line, do not run code in the handler

Each `CTRL+X` chord is a PSReadLine handler that does `RevertLine()`, `Insert('bd')` and `AcceptLine()`. This is the
equivalent of bash's `bind '"\C-x\C-d": "bookmark_dirs\15"'`, not `bind -x`. The command therefore runs at the
normal prompt, where `Read-Host` and `fzf` work, and none of the raw-mode constraints of the bash palette apply. That
is also why the palette can simply `Read-Host` a command's `@args` before running it, instead of pre-filling the
command line. Handlers are only registered when the PSReadLine module is loaded (interactive sessions), so importing
the module in a script or in CI is side-effect free.

### Bookmark jump functions

Bookmarks are read from the bash-format file with the same greedy regex as `_i_bookmarks_valid_entries`. Each one
becomes a global function built from **single-quoted literals only**, escaped with
`CodeGeneration.EscapeSingleQuotedStringContent` (which also handles the typographic quotes PowerShell accepts as
single quotes). A folder named `x$(...)y` therefore can never execute code, unlike the bash alias (see
`KNOWN_ISSUES.md`). A bookmark whose name is already a command is skipped. The functions are removed with
`Remove-Item Function:\NAME`, without a scope qualifier: from the module scope the lookup walks up to the global
function, whereas `Function:\global:NAME` silently removes nothing.

### Windows PowerShell 5.1 constraints

Windows PowerShell 5.1 reads BOM-less `.ps1` files as ANSI, so the module sources are kept pure ASCII. Under ANSI
decoding a UTF-8 em-dash turns into bytes that PowerShell treats as a quote character. The syntax also avoids 7-only
features (`??`, ternary, `&&`/`||`), and `$IsWindows` is only read after checking `PSEdition` (it does not exist in 5.1).
