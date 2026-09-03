# Command History

> **Re-run a previous command — number-jump or fuzzy search, just like `rd` for directories.**

> 🇫🇷 [Version française](fr/feature-history.md)

Requires [`fzf`](https://github.com/junegunn/fzf#installation) for the fuzzy filter (a numbered picker is used otherwise).

---

## Re-run a previous command

```bash
lc
```

Or press `CTRL+X+L`.

`lc` reads bash's own history — the same list the `history` builtin shows — most recent first,
deduplicated so a repeated command only appears once (at its most recent position).

If [`fzf`](https://github.com/junegunn/fzf#installation) is installed, `lc` opens an **incremental
filter** that supports both styles at once — each entry is shown with its index number, so:
- typing **digits** (e.g. `3`) jumps straight to that numbered entry, same as the classic picker;
- typing **letters** (e.g. `docker`) fuzzy-filters the list live by command text.

Use the arrow keys to move, `Enter` to select, `Esc` to cancel. Without `fzf` — or with fuzzy mode
disabled — `lc` falls back to the classic numbered picker: a plain list, type a number and press
Enter to select it.

Either way, the selected command is **never run blindly**: it is preloaded onto an editable
`Run>` prompt so you can review it, tweak it, or clear the line to cancel before pressing Enter.

### Demo

```
$ lc
  1) git status
  2) docker ps -a
  3) rm -rf build/
Select [1-3] (Enter to cancel): 3
Run> rm -rf build/
```

### Configuration

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_LAST_COMMAND_MAX` | `50` | Maximum number of history entries considered |
| `NIXLPER_LAST_COMMAND_FUZZY` | `true` | Use the `fzf` fuzzy filter when `fzf` is installed; `false` always uses the numbered picker |

Configure via `nconf` (`CTRL+X+C`) or `~/.config/nixlper/nixlper.conf`.

---

[← Back to home](index.md)
