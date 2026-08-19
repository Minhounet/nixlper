# Process Management

> **Kill any process by name or port — interactively, without hunting for PIDs.**

> 🇫🇷 [Version française](fr/feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Interactive kill — choose by pattern or port |
| `pc PORT` | Port quick-check — process name, PID and a suggested action for a port |

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

Enter a port number — nixlper looks up the process listening on it and prints its name,
PID, and a suggested action, without prompting to kill it.

```bash
pc 8080
```

If the port is free, nixlper says so and does nothing else.

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
Port 8080 -> process 'java' (PID 12345)
UID   PID  PPID  C STIME TTY TIME     CMD
user  12345 1    0 10:00 ?  00:00:05 java -jar myapp.jar
Suggested action: run 'ik --port 8080' to kill it interactively, or 'kill -9 12345' directly.
```

---

[← Back to home](index.md)
