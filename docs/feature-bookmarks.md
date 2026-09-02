# Bookmarks

> **Save your most-visited directories and jump back instantly.**

> 🇫🇷 [Version française](fr/feature-bookmarks.md)

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+B` | — | Add or remove a bookmark for the current folder |
| `CTRL+X+D` | `bd` | Display saved bookmarks and jump to one |

---

## Demo

<!-- TODO: add demo GIF — navigate to a folder, CTRL+X+B to bookmark it, CTRL+X+D to list bookmarks, select one to jump -->

---

## Usage

### Add a bookmark

Navigate to any folder, then press `CTRL+X+B`. You will be prompted to enter a name for the bookmark.

```
$ cd /var/log/nginx
$ # press CTRL+X+B
Bookmark name: nginx-logs
✔ Bookmark "nginx-logs" added.
```

### Remove a bookmark

Press `CTRL+X+B` again from any directory. If the current folder is already bookmarked, you will be offered the option to remove it.

### Jump to a bookmark

Press `CTRL+X+D` (or run `bd`) to display all saved bookmarks and jump to one.

If [`fzf`](https://github.com/junegunn/fzf#installation) is installed, this opens an **incremental filter** that supports both selection styles at once — each entry is shown with its index number, so:
- typing **digits** (e.g. `3`) jumps straight to that numbered entry;
- typing **letters** (e.g. `nginx`) fuzzy-filters the list live by bookmark name or path.

Use the arrow keys to move, `Enter` to jump, `Esc` to cancel. Without `fzf` — or with fuzzy mode disabled — falls back to the classic numbered picker: type a number and press Enter to jump there.

Bookmarks whose directory has been removed since they were saved are skipped automatically.

You can also type the bookmark's own name directly at any prompt — since each bookmark is a real bash alias, typing `nginx-logs` jumps to it exactly like typing any other command. The picker above is a second way to find it when you don't remember the exact name.

---

## Storage

Bookmarks are stored in `NIXLPER_BOOKMARKS_FILE` (default: `$NIXLPER_INSTALL_DIR/.nixlper_bookmarks` for manual install, `~/.local/share/nixlper/bookmarks` for RPM/DEB).

### Configuration

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_BOOKMARKS_FILE` | `~/.local/share/nixlper/bookmarks` | Bookmarks file path |
| `NIXLPER_BOOKMARKS_FUZZY` | `true` | Use the `fzf` fuzzy filter when `fzf` is installed; `false` always uses the numbered picker |

Configure via `nconf` (`CTRL+X+C`) or `~/.config/nixlper/nixlper.conf`.

---

[← Back to home](index.md)
