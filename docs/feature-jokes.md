# Jokes

> **A random dev pun, because life is too short for serious commits.**

> 🇫🇷 [Version française](fr/feature-jokes.md)

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+K` | `joke` | Show a random developer pun or joke |

---

## How it works

Nixlper ships with a small curated set of developer puns in French and English.
Running `joke` (or pressing `CTRL+X+K`) picks one at random from the list that matches your language.

Language selection follows this priority:
1. `NIXLPER_JOKE_LANG` if set to `fr` or `en`.
2. Auto-detection from `$LANG` when `NIXLPER_JOKE_LANG=auto` (the default): a locale starting with `fr` picks the French list, anything else picks English.

---

## Configure the language

Set `NIXLPER_JOKE_LANG` via `nconf` (`CTRL+X+C`) or directly in `~/.config/nixlper/nixlper.conf`:

```bash
export NIXLPER_JOKE_LANG=fr    # always French
export NIXLPER_JOKE_LANG=en    # always English
export NIXLPER_JOKE_LANG=auto  # detect from $LANG (default)
```

---

[← Back to home](index.md)
