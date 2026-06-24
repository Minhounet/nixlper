# Process Management

> **Kill any process by name or port — interactively, without hunting for PIDs.**

| Alias | Description |
|---|---|
| `ik` | Interactive kill — choose by pattern or port |

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

---

## Example

```bash
$ ik
Kill by [p]attern or [P]ort? p
Pattern: myapp
  PID 12345 — java -jar myapp.jar
Kill PID 12345? [y/N] y
Killed.
```

---

[← Back to home](index.md)
