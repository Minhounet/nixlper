# Admin Notice

> **Leave a message for whoever logs in next — root or any account.**

> 🇫🇷 [Version française](fr/feature-admin-notice.md)

| Alias | Description |
|---|---|
| `bset` | Register a notice shown to everyone at next login |
| `bshow` | Show the current notice on demand |
| `bclear` | Remove the current notice |

---

## Usage

```bash
bset
```

`bset` is interactive: it prompts for the message text, then for an optional expiry in days.

- Leave the expiry blank for a **persistent** notice — shown at every login until you run `bclear`.
  Use this for anything that must stay visible until it's actually resolved, like a workaround.
- Enter a number of days for a notice that **disappears on its own** after that many days.
  Expiry is checked at login time, so an expired notice may linger harmlessly until the next
  person actually logs in — it isn't removed by a background timer.

This is independent from nixlper's own welcome message and tips — it's for operator-to-operator
notices about the machine itself (a reboot pending, a temporary workaround, a change someone
should know about).

---

## Example

```bash
$ bset
Message to broadcast at next login: Temporary DNS workaround in place, see ticket #123
Expire in how many days? (blank = persistent until bclear): 7
2026-08-21 09:12:03 INFO Notice set, expires in 7 day(s).
```

At the next login (any user):

```
⚠️  ──────────────────────────── ADMIN NOTICE ────────────────────────────
Temporary DNS workaround in place, see ticket #123
────────────────────────────────────────────────────────────────────────
```

---

## Removing a notice

```bash
bclear
```

Deletes the notice immediately, regardless of any expiry that was set.

---

## Configuration

Available via `nconf` (`CTRL+X+C`):

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_DISABLE_BROADCAST_MESSAGE` | `false` | Suppress the admin notice at login |
| `NIXLPER_BROADCAST_MESSAGE_FILE` | see below | Where the notice is stored |

| Install type | Default path |
|---|---|
| Manual install | `$NIXLPER_INSTALL_DIR/broadcast_message` |
| RPM / DEB | `/etc/nixlper/broadcast_message` |

Only whoever can write to that path (typically root on a system-wide install) can register or
clear a notice — every user can read it.

---

[← Back to home](index.md)
