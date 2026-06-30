# Debug Mode

> 🇫🇷 [Version française](fr/feature-debug.md)

Debug mode lets you inspect nixlper's resolved configuration and trace individual function calls — without flooding your interactive shell with a global `set -x`.

---

## Commands

### Toggle debug mode — `CTRL+X+Z`

```
nixlper_debug_toggle
```

Toggles `NIXLPER_DEBUG` for the current shell session.

- **On**: prints a summary of all resolved `NIXLPER_*` variables.
- **Off**: prints a confirmation message.

To enable permanently across sessions, set `NIXLPER_DEBUG=true` via `nconf`.

---

### Trace a function — `ndebug`

```
ndebug <function> [args...]
```

Wraps the named nixlper function in `set -x` / `set +x` so only that function's execution is traced. This avoids the noise that global `set -x` produces in an interactive shell (readline, `PROMPT_COMMAND`, and other shell internals would otherwise flood the output).

**Examples:**

```bash
ndebug navigate
ndebug _check_update
ndebug _display_existing_bookmarks
```

**Output format:**

```
[NIXLPER DEBUG] Tracing: navigate
──────────────────────────────────────────────────────────
+ <traced lines>
──────────────────────────────────────────────────────────
[NIXLPER DEBUG] Exit code: 0
```

If the function is not found, `ndebug` prints an error and suggests:

```bash
declare -F | grep nixlper   # list all loaded nixlper functions
```

---

### Show configuration — `ndbconf`

```
ndbconf
```

Prints the resolved values of all `NIXLPER_*` variables without toggling debug mode. Useful for a one-shot inspection.

---

## Configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `NIXLPER_DEBUG` | bool | `false` | Enable debug mode (config summary at login, `ndebug` tracing) |

Set via `nconf` or temporarily with `export NIXLPER_DEBUG=true` in the current session.

---

## Keybindings & Aliases

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+Z` | — | Toggle debug mode on/off |
| — | `ndebug` | Trace a single function call |
| — | `ndbconf` | Show all resolved `NIXLPER_*` variables |
