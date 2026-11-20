# Files & Folders

> **Mark, open, snapshot, rename, and safely delete files — all from the keyboard.**

> 🇫🇷 [Version française](fr/feature-files-folders.md)

---

## Mark a folder for quick return

```bash
c       # mark current folder
gc      # jump back to the marked folder from anywhere
```

### Demo

<!-- TODO: add demo GIF — cd deep into a tree, type c, cd elsewhere, type gc to jump back -->

---

## Mark a file for quick open

```bash
cf FILEPATH    # mark a file
gcf            # open the marked file in $NIXLPER_EDITOR from anywhere
```

---

## Clipboard

```bash
cpcb [FILEPATH]    # copy full path of file to clipboard (defaults to current directory)
cpdcb FILEPATH     # copy full path of the directory containing the file
```

Requires `xclip`, `xsel`, or `pbcopy`.

### Demo

<!-- TODO: add demo GIF — cpcb on a file, paste into another command -->

---

## Snapshot & restore

```bash
sn FILEPATH          # snapshot a file to the snapshots area
re [FILEPATH]        # restore a file — omit FILEPATH for an interactive picker
```

Snapshots are stored in `NIXLPER_SNAPSHOT_DIR`. The original file is never deleted — `sn` is a safety copy, not a move.

### Demo

<!-- TODO: add demo GIF — sn a config file, modify it, re to restore interactively -->

---

## Search & replace in a file

```bash
rp FILENAME
```

Interactive search and replace using **vi's `:s` syntax** — no more cryptic `sed` one-liners. `rp` asks four questions, then builds and runs the equivalent of `:%s/SEARCH/REPLACE/FLAGS` (through `ex`, which ships with vim):

```text
$ rp app.conf
Search  (vi regex): ^timeout=\(.*\)
Replace (\1 and & work as in vi): retry=\1
Lines   (Enter = all, or 10,20 or /start/,/end/):
Flags   (g = every match per line, i = ignore case, c = confirm each; default g):
   1 - timeout=30
   1 + retry=30
1 line(s) would change in app.conf
Apply? (y/n, default is n): y
```

- **Preview first** — only the changed lines are shown, nothing is written until you answer `y`.
- **Delimiter handled for you** — paths such as `/usr/bin` need no `\/` escaping.
- **Flags** — `g` (default) every match on a line, `i` ignore case, `c` confirm each match one by one, as in vi (needs `vim`).
- **Line range** — leave empty for the whole file, or give `10,20`, `5`, `/start/,/end/`.
- **Undo** — the file is snapshotted before it is edited: run `re FILENAME` to restore it. If a snapshot already exists you are asked before it is overwritten. Disable with `NIXLPER_REPLACE_SNAPSHOT=false`.
- **Pipes** — a bare `|` is refused (ex would treat it as a command separator): use `[|]` in the search, `\|` in the replacement.
- Binary and read-only files are refused. Requires `ex` (part of vim).

---

## Rename by pattern

```bash
rn FILENAME PATTERN [REPLACEMENT]
```

Remove or replace a pattern in a filename without typing the full `mv` command.

```bash
rn file_peppa.txt _peppa              # → file.txt       (remove pattern)
rn test-old.txt -old -new             # → test-new.txt   (replace pattern)
```

---

## Open most recent file

```bash
olf
```

Opens the most recently modified file in the current directory tree with `$NIXLPER_EDITOR`. Useful after a build or log generation.

---

## Safe delete

These commands display a pre-filled `rm -i` command for you to review and confirm — they are never executed automatically.

| Shortcut | Generated command |
|---|---|
| `CTRL+X+E` | `rm -i -rf /current/folder && cd ..` — delete the current folder |
| `CTRL+X+R` | `rm -i -rf /current/folder/*` — delete contents of the current folder |

The commands appear on your command line. You press Enter to run them, giving you a final chance to abort.

> This keeps dangerous `rm -rf` calls out of your shell history while still letting you act quickly.

---

## Add current path to `$PATH`

```bash
ap
```

Prepends the current directory to `PATH` in `~/.bashrc` and sources it immediately. Useful when you're developing a script and want to run it without `./`.

---

[← Back to home](index.md)
