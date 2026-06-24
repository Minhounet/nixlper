# SSH Connections

> **Connect to saved SSH hosts in seconds — password once, passwordless forever after.**

> ⚠️ **Experimental** — not yet tested in a live environment. Please [report issues](https://github.com/Minhounet/nixlper/issues).

Requires [`fzf`](https://github.com/junegunn/fzf#installation).

---

## Commands

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+S` | `sc` | Open SSH picker — select a host and connect |
| — | `sca` | Add a new SSH connection |
| — | `scr` | Remove a saved connection (fzf picker) |
| — | `scl` | List all saved connections |

---

## Demo

<!-- TODO: add demo GIF — scl to show connections, CTRL+X+S to pick one and connect -->

---

## First use

On your first connection to a new host, nixlper:
1. Generates `~/.ssh/nixlper_id_rsa` if it does not exist.
2. Uses `ssh-copy-id` to push the key to the remote host.
3. Asks for your password **once**.

Every subsequent connection uses the key — no password needed.

---

## Adding a connection

```bash
sca
```

You will be prompted for:
- **Label** — a short name for the connection (e.g. `prod-server`)
- **User** — the SSH username
- **Host** — hostname or IP
- **Port** — default `22`
- **Identity file** — leave empty to use the global default (`NIXLPER_SSH_IDENTITY_FILE`)

---

## Connection file format

Connections are stored in `~/.config/nixlper/ssh_connections`, one per line:

```
label|user|host|port|identity_file
# example — leave identity_file empty for the global default
myserver|alice|192.168.1.10|22|
prod|deploy|10.0.0.5|2222|~/.ssh/prod_key
```

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_SSH_CONNECTIONS_FILE` | `~/.config/nixlper/ssh_connections` | Connections file path |
| `NIXLPER_SSH_IDENTITY_FILE` | `~/.ssh/nixlper_id_rsa` | Default SSH key |

Configure via `nconf` (`CTRL+X+C`).

---

[← Back to home](index.md)
