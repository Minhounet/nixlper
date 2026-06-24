# User Management

> **Switch to another user without losing your current directory.**

> 🇫🇷 [Version française](fr/feature-users.md)

| Alias | Description |
|---|---|
| `sucd USER` | `su - USER` and immediately `cd` back to the current folder |

---

## Demo

<!-- TODO: add demo GIF — in /var/log/app, type sucd deploy, land in the same folder as deploy user -->

---

## Usage

```bash
sucd deploy
```

Equivalent to `su - deploy` followed by `cd /your/current/path`. Useful when you need to run commands as another user in the same location.

---

## Notes

- Requires `su` permissions for the target user.
- The current directory must be accessible by the target user for the `cd` to succeed.

---

[← Back to home](index.md)
