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
