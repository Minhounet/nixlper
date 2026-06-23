# Target Staging

> **Collect files from anywhere and copy or pack them in one shot.**
> Useful for shuttling files to a server via `/tmp`, or gathering scattered files before a transfer.

The target folder is world-readable (default: `/tmp/nixlper_target`).

---

## Commands

| Command | Description |
|---|---|
| `tc FILEPATH` | Copy a file directly to the target folder (`chmod 644`) |
| `tm FILEPATH` | Mark a file for later batch pack |
| `tml` | List currently marked files |
| `tum` | Remove a file from the mark list (numbered picker) |
| `tcm` | Clear all marks without copying |
| `tp` / `CTRL+X+Y` | Pack all marked files into a timestamped `.tgz` in the target folder, then clear marks |
| `tsd [DIRPATH]` | Show or change the target folder for this session |
| `tclean` | Delete all files in the target folder (confirmation required) |

`tcN` and `tmN` shortcuts are also available directly from [navigation](feature-navigation.md) and `fan` results.

---

## Typical workflow

```bash
fan report           # find files matching "report"
tm2                  # mark file 2
tm5                  # mark file 5
tml                  # review the list
tp                   # pack → /tmp/nixlper_target/nixlper_pack_20260623_143022.tgz
tclean               # wipe the target folder when done
```

### Demo

<!-- TODO: add demo GIF — fan, tm2, tm5, tml, tp, show the resulting .tgz -->

---

## Configuration

Change the default target folder via `nconf` (`CTRL+X+C`) → `NIXLPER_TARGET_DIR`, or set it in `~/.config/nixlper/nixlper.conf`:

```bash
NIXLPER_TARGET_DIR=/home/shared/transfer
```

To change the folder only for the current session (no config change):

```bash
tsd /home/shared/transfer
```

---

[← Back to home](index.md)
