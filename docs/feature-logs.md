# Logs

> **Follow a log file and highlight the lines you actually care about.**

> 🇫🇷 [Version française](fr/feature-logs.md)

| Alias | Description |
|---|---|
| `logtail` | Follow a file, showing only lines matching a pattern, highlighted |

---

## Usage

```bash
logtail FILE PATTERN
```

`logtail` wraps `tail -F FILE | grep --color PATTERN`: it follows `FILE` (surviving log
rotation, since it uses `tail -F`) and prints only the lines matching `PATTERN`, with the
match highlighted in colour. Press `CTRL+C` to stop.

`PATTERN` is an extended regular expression (`grep -E`).

---

## Example

```bash
$ logtail /var/log/app.log "ERROR|WARN"
2026-08-19 10:03:21 ERROR Connection refused
2026-08-19 10:03:45 WARN  Retry attempt 2
```

---

## Configuration

Available via `nconf` (`CTRL+X+C`):

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_LOGTAIL_IGNORE_CASE` | `false` | Case-insensitive pattern matching |
| `NIXLPER_LOGTAIL_LINES` | `10` | Initial lines shown before following |

---

[← Back to home](index.md)
