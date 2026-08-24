# Process Management

> **Kill any process by name or port — interactively, without hunting for PIDs.**

> 🇫🇷 [Version française](fr/feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Interactive kill — choose by pattern or port |
| `pc PORT` | Port quick-check — process name, PID, command line, suggested action (read-only) |

---

## Demo

<!-- TODO: add demo GIF — ik, choose "by pattern", type "java", confirm kill -->

---

## Usage

```bash
ik
```

You will be asked to choose a kill mode:

### Kill by pattern

Enter any string — nixlper finds all processes whose name or command line matches, shows them, and asks for confirmation before killing.

### Kill by port

Enter a port number — nixlper finds the process listening on that port and offers to kill it.

Port detection uses `ss` (iproute2) if available, with `netstat` (net-tools) as fallback.

### Port quick-check

`pc PORT` looks up what is listening on a port without killing anything — process name, PID,
full command line, and a suggested action (kill via `ik --port` or `kill -9`). Useful when you
just want to identify what's occupying a port before deciding what to do about it.

```bash
pc 8080
```

Set `NIXLPER_PORT_CHECK_SHOW_CMDLINE=false` (via `nconf`) to hide the full command line in the
output, e.g. on shared systems where it may reveal sensitive arguments.

---

## Example

```bash
$ ik
Kill by [p]attern or [P]ort? p
Pattern: myapp
  PID 12345 — java -jar myapp.jar
Kill PID 12345? [y/N] y
Killed.

$ pc 8080
Port 8080 is in use by PID 12345 (node)
Command: node server.js
Suggested action: run 'ik --port 8080' to kill it interactively, or 'kill -9 12345' directly.
```

---

[← Back to home](index.md)
