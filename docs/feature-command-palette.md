# Command Palette

> **The fastest way to discover and run any Nixlper command.**
> You don't need to memorise shortcuts — just open the palette and type.

| Shortcut | Alias |
|---|---|
| `CTRL+X+A` | `fa` |

Requires [`fzf`](https://github.com/junegunn/fzf#installation).

---

## What it does

Opens a fuzzy-searchable popup listing every available Nixlper command with its:
- Description
- Category
- Keybinding
- Alias

Type any word — command name, description, or category — and the list filters instantly.
Press **Enter** to run the selected command.

---

## Demo

<!-- TODO: add demo GIF — open palette, type "book", select "display bookmarks", press Enter -->

---

## How commands are executed

The palette handles two kinds of commands differently:

- **Plain commands** — executed immediately on selection (e.g. display bookmarks, show logo).
- **Commands that need arguments or interactive input** — placed on your command line so you can type the arguments and press Enter. These are marked with `@args` or `@interactive` in the source.

This distinction exists because the palette runs inside readline's raw mode, where the `read` builtin cannot receive keystrokes. Placing the command on the line lets you use normal TAB completion.

---

## Tips

- Press `ESC` to close the palette without running anything.
- You can search by category (e.g. type `navigation` or `macro`).
- Every new feature you add via custom scripts with `@cmd-palette` annotations automatically appears here.

---

[← Back to home](index.md)
