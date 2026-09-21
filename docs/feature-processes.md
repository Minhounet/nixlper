# Process Management

> **Kill any process by name or port — one fuzzy picker, no PID hunting.**

> 🇫🇷 [Version française](fr/feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Interactive kill — one fuzzy picker matching on command, PID **and** port |
| `ik PATTERN` | Same picker, opened pre-filtered on `PATTERN` |
| `ik --pattern VALUE` / `ik --port VALUE` | Explicit modes, without the picker |
| `pc PORT` | Port quick-check — process name, PID, command line, suggested action (read-only) |

---

## Demo

<!-- TODO: add demo GIF — ik, type 8080, TAB a second process, ENTER, confirm -->

---

## Usage

```bash
ik
```

No mode to choose. `ik` lists every process in a single `fzf` picker, each row carrying the
PID, the ports it listens on, its user and its full command line:

```
  PID     PORTS           USER       COMMAND
> 1234    :8080,:9090     user       java -jar myapp.jar
  5678    -               user       node worker.js
  9012    :5432           postgres   postgres -D /var/lib/pgsql/data

  3/187
  Kill > 8080
  Filter by command, PID or port | TAB: mark several | ENTER: validate | ESC: cancel
```

Because the port lives on the same line as the command, **one query searches both**: type
`8080` when you only know the port, `java` when you only know the name, `1234` when you have
the PID. No need to decide which one you are searching by.

- `TAB` marks several processes, `ENTER` validates.
- The marked processes are listed back and confirmed before anything is killed.
- `ESC` cancels.
- Your own shell is never listed — you cannot fat-finger your session away.

Port detection uses `ss` (iproute2) if available, with `netstat` (net-tools) as fallback. With
neither installed the ports column simply shows `-` and the picker still filters by command.

### Pre-filtering

```bash
ik java
```

Opens the same picker with `java` already typed in the query.

### Explicit modes

The historical flags are still available — useful when you already know exactly what you want,
or in a script-like one-liner:

```bash
ik --port 8080      # kill whatever listens on 8080
ik --pattern java   # numbered kill-by-pattern flow
```

Without `fzf` — or with `NIXLPER_KILL_FUZZY=false` (via `nconf`) — `ik` falls back to the
historical prompt asking for a kill mode (port/pattern) and then a value.

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
# type "8080", TAB to also mark the stale worker, ENTER

About to kill 2 process(es):
  1234    :8080,:9090     user       java -jar myapp.jar
  5678    -               user       node worker.js

Kill process(es) above with kill -9? (y/n, default is n)y
Killed 1234
Killed 5678
-> DONE

$ pc 8080
Port 8080 is in use by PID 12345 (node)
Command: node server.js
Suggested action: run 'ik --port 8080' to kill it interactively, or 'kill -9 12345' directly.
```

---

## Settings

| Variable | Default | Effect |
|---|---|---|
| `NIXLPER_KILL_FUZZY` | `true` | Use the `fzf` unified picker for `ik` when `fzf` is installed |
| `NIXLPER_PORT_CHECK_SHOW_CMDLINE` | `true` | Show the full command line in `pc` output |

---

[← Back to home](index.md)
