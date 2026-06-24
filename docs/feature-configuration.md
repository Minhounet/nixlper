# Configuration

> **Customize every aspect of Nixlper interactively — no manual file editing needed.**

| Shortcut | Alias |
|---|---|
| `CTRL+X+C` | `nconf` |

Requires [`fzf`](https://github.com/junegunn/fzf#installation).

---

## Demo

<!-- TODO: add demo GIF — CTRL+X+C, browse settings, change NIXLPER_EDITOR, save -->

---

## How it works

`nconf` opens a fuzzy-searchable list of all configurable settings. Select any entry and press Enter:

- **Boolean / enum settings** — presented as a selection list.
- **Text / integer settings** — presented as a pre-filled prompt.

Only values that differ from the default are written to `~/.config/nixlper/nixlper.conf`. The file stays minimal and readable.

Changes take effect in new shells. To apply immediately: `source ~/.bashrc`.

---

## Common settings

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_EDITOR` | `vim` | Editor for file open commands |
| `NIXLPER_NAVIGATE_MODE` | `tree` | Navigation mode (`tree` or `flat`) |
| `NIXLPER_DISABLE_WELCOME_MESSAGE` | `false` | Suppress startup banner |
| `NIXLPER_DISABLE_TIPS` | `false` | Suppress startup tip |
| `NIXLPER_UPDATE_CHECK` | `true` | Auto-check for updates at login |
| `NIXLPER_UPDATE_AUTO` | `false` | Auto-install detected updates |
| `NIXLPER_UPDATE_CHANNEL` | `stable` | Update channel (`stable` / `edge` / `off`) |
| `NIXLPER_TARGET_DIR` | `/tmp/nixlper_target` | Staging folder for copy/mark/pack |

## Advanced settings

| Variable | Description |
|---|---|
| `NIXLPER_UPDATE_CHECK_INTERVAL` | Seconds between auto-checks (default `86400`) |
| `NIXLPER_UPDATE_TIMEOUT` | Network probe timeout in seconds (default `2`) |
| `NIXLPER_BOOKMARKS_FILE` | Path to bookmarks file |
| `NIXLPER_SNAPSHOT_DIR` | Path to snapshots directory |
| `NIXLPER_CUSTOM_DIR` | Path to custom scripts directory |
| `NIXLPER_SSH_CONNECTIONS_FILE` | Path to SSH connections file |
| `NIXLPER_SSH_IDENTITY_FILE` | Default SSH identity key |

---

## Config file location

Settings are stored in `~/.config/nixlper/nixlper.conf` (user) and `/etc/nixlper/nixlper.conf` (system, RPM/DEB installs).

User settings always take priority over system settings.

---

## Migration from `~/.bashrc`

If your Nixlper variables are still in `~/.bashrc` (older manual install), `nconf` will offer a one-time migration:
- Moves all `NIXLPER_*` exports to `~/.config/nixlper/nixlper.conf`
- Leaves `~/.bashrc` with only the `source` line
- Creates a backup before making any changes

If migration fails, recovery instructions are printed, including how to restore the backup.

---

## Custom scripts

Any script placed in `NIXLPER_CUSTOM_DIR` (default: `$NIXLPER_INSTALL_DIR/custom`) is automatically sourced at login, letting you extend Nixlper with your own aliases and functions.

---

[← Back to home](index.md)
