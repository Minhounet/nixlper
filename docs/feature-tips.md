# Tips

> **Learn Nixlper shortcuts progressively — one tip at a time.**

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+T` | `tip` | Show a random tip on demand |

---

## How it works

A tip is shown automatically each time you open a new shell, cycling through all available tips in order. This lets you gradually discover features without being overwhelmed.

Use `tip` or `CTRL+X+T` at any time to see another tip on demand.

---

## Disable startup tips

If you prefer a clean shell start, disable the automatic tip in `nconf` (`CTRL+X+C`) → `NIXLPER_DISABLE_TIPS`, or add to `~/.config/nixlper/nixlper.conf`:

```bash
NIXLPER_DISABLE_TIPS=true
```

The `tip` command and `CTRL+X+T` shortcut continue to work regardless of this setting.

---

[← Back to home](index.md)
