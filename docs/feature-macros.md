# Macros

> **Record a sequence of commands once and replay it with a single shortcut.**
> No scripting required — just record what you type.

---

## Shortcuts

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+P` | `sr` | Start recording |
| `CTRL+P, CTRL+P` | `fr` | Stop recording (binds recorded commands to `CTRL+X+CTRL+X`) |
| `CTRL+X+CTRL+X` | — | Play the recorded macro |
| `CTRL+P+CTRL+L` | — | Re-bind and replay the last recorded macro (survives session restarts) |

---

## Demo

<!-- TODO: add demo GIF — CTRL+P to start, type a few commands, CTRL+P CTRL+P to stop, CTRL+X+CTRL+X to replay -->

---

## How it works

1. Press `CTRL+P` to start recording. The shell continues working normally — all commands you run are captured.
2. Press `CTRL+P, CTRL+P` to stop. The recorded sequence is bound to `CTRL+X+CTRL+X`.
3. Press `CTRL+X+CTRL+X` at any time to replay the full sequence.

The last recorded macro is persisted to `NIXLPER_LAST_MACRO_BINDING_FILE`, so you can restore it in a new shell session with `CTRL+P+CTRL+L` without re-recording.

---

## Example

```bash
# Start recording
# (press CTRL+P)

cd /var/log
grep -i error syslog | tail -20

# Stop recording
# (press CTRL+P then CTRL+P)

# Now press CTRL+X+CTRL+X any time to replay those two commands
```

---

[← Back to home](index.md)
