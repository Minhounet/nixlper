# Nixlper — Keyboard-driven file management for Unix

Nixlper brings [Total Commander](https://www.ghisler.com/accueil.htm)-style keyboard shortcuts to your Unix shell.
No GUI required — just your terminal.

> 🚀 **Current version: v2.2.0** — [Release notes](https://github.com/Minhounet/nixlper/releases)

---

## Install in one line

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh | bash
```

Then open a new shell. That's it.

➜ [Full installation guide](installation.md)

---

## Features

| Goal | Page |
|---|---|
| 🔍 Discover and run any command instantly | [Command Palette](feature-command-palette.md) |
| 📂 Browse your filesystem interactively | [Navigation](feature-navigation.md) |
| 🔖 Jump to frequent locations | [Bookmarks](feature-bookmarks.md) |
| 📋 Copy & move files | [Files & Folders](feature-files-folders.md) |
| 🎯 Collect files from anywhere and transfer them | [Target Staging](feature-target-staging.md) |
| 🔁 Automate repetitive commands | [Macros](feature-macros.md) |
| ⚙️ Customize nixlper to your taste | [Configuration](feature-configuration.md) |
| 🔑 Connect to SSH hosts instantly | [SSH Connections](feature-ssh.md) |
| ⚡ Kill processes by name or port | [Process Management](feature-processes.md) |
| 👤 Switch users without losing your place | [User Management](feature-users.md) |
| 🔄 Stay up to date automatically | [Updates](feature-updates.md) |
| 💡 Learn tips as you work | [Tips](feature-tips.md) |

---

## Key concepts

- **Everything is a shortcut.** All features are reachable via `CTRL+X+<key>` combinations or short aliases (e.g. `fa`, `ik`, `sn`).
- **Don't remember anything.** Open the [Command Palette](feature-command-palette.md) (`CTRL+X+A`) and fuzzy-search for what you need.
- **Requires `fzf`** for the palette, navigation, SSH picker, and config editor. Install it with your package manager (`brew install fzf`, `dnf install fzf`, `apt install fzf`).

---

## Quick reference

| Shortcut | What it does |
|---|---|
| `CTRL+X+A` | Open command palette |
| `CTRL+X+N` | Interactive file browser |
| `CTRL+X+B` | Add/remove bookmark |
| `CTRL+X+D` | Show bookmarks |
| `CTRL+X+C` | Open configuration editor |
| `CTRL+X+S` | SSH connect picker |
| `CTRL+X+W` | Check for updates |
| `CTRL+X+H` | In-shell help |
| `CTRL+X+U` | Go up one directory |
| `CTRL+P` | Start/stop macro recording |

---

---

## About the author

Hi, I'm **Quang Minh** — an ECM expert consultant with a soft spot for software craftsmanship and Java.
I care deeply about clean, well-crafted code, even if I'm still on the journey to master it.

Nixlper was born from a simple obsession: **being fast at the terminal**. If I can shave a few keystrokes off a daily workflow, I will.

> *"Développer sérieusement sans se prendre au sérieux."*
> *(Develop seriously, without taking yourself too seriously.)*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Quang%20Minh-blue?logo=linkedin)](https://www.linkedin.com/in/quang-minh-t-131048155)

---

[GitHub Repository](https://github.com/Minhounet/nixlper) · [Report an issue](https://github.com/Minhounet/nixlper/issues) · [Release notes](https://github.com/Minhounet/nixlper/releases)
