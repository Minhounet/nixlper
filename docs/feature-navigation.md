# Navigation

> **Browse your filesystem interactively — open files, jump into folders, search by name or content, all without leaving the terminal.**

Requires [`fzf`](https://github.com/junegunn/fzf#installation). Tree mode also requires `tree`.

---

## Interactive browser

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+N` | — | Open interactive file browser |
| `CTRL+X+U` | — | Go up one directory (`cd ..`) |

### Demo

<!-- TODO: add demo GIF — CTRL+X+N, navigate tree, open a file with vN, jump to folder with cdfN -->

### How it works

Running `CTRL+X+N` displays the contents of the current directory with numbered shortcuts for each item:

| Shortcut | Action |
|---|---|
| `vN` | Open file N in `$NIXLPER_EDITOR` |
| `nN` or `CTRL+X+N` | Navigate into folder N |
| `cdfN` | `cd` to the folder containing item N |
| `dN` | Delete item N (with confirmation) |
| `tcN` | Copy item N to the [target staging folder](feature-target-staging.md) |
| `tmN` | Mark item N for batch pack |

Two display modes are available:

- **tree** (default) — uses the `tree` command for a visual hierarchy
- **flat** — plain list, no external dependency

Switch modes via `nconf` (`CTRL+X+C`) → `NIXLPER_NAVIGATE_MODE`, or toggle size/permission display with:

```bash
toggle_navigation_mode
```

---

## Go to file's folder

```bash
cdf FILEPATH
```

Jumps directly to the directory containing `FILEPATH`. Useful when you know a file's path but want to land in its folder.

---

## Search by name

```bash
fan PATTERN
```

Runs `find . -iname "*PATTERN*"` and displays results with the same numbered shortcuts as the browser (`vN`, `cdfN`, `dN`, `tcN`, `tmN`).

### Demo

<!-- TODO: add demo GIF — fan report, results appear, open one with vN, delete another with dN -->

---

## Search by content

```bash
fag PATTERN
```

Runs `grep -rn PATTERN .` and displays each match with a `vN` shortcut that opens the file **directly at the matching line** in your editor.

### Demo

<!-- TODO: add demo GIF — fag TODO, results appear, press v1 to jump to the matching line -->

---

[← Back to home](index.md)
