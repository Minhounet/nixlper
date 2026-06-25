# Bookmarks

> **Save your most-visited directories and jump back instantly.**

> 🇫🇷 [Version française](fr/feature-bookmarks.md)

| Shortcut | Description |
|---|---|
| `CTRL+X+B` | Add or remove a bookmark for the current folder |
| `CTRL+X+D` | Display all saved bookmarks |

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

Press `CTRL+X+D` to display all saved bookmarks. Select one and press Enter — nixlper `cd`s directly to that folder.

---

## Storage

Bookmarks are stored in `NIXLPER_BOOKMARKS_FILE` (default: `$NIXLPER_INSTALL_DIR/.nixlper_bookmarks` for manual install, `~/.local/share/nixlper/bookmarks` for RPM/DEB).

Configure the path via `nconf` (`CTRL+X+C`).

---

[← Back to home](index.md)
