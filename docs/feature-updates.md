# Updates

> **Nixlper checks for new versions automatically and can update itself.**

> 🇫🇷 [Version française](fr/feature-updates.md)

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+W` | `nu` | Check for a newer version now |
| `CTRL+X+G` | `nw` | Show ongoing work planned for the next release |

---

## Demo

<!-- TODO: add demo GIF — nu showing "new version available", then running the update command -->

---

## Channels

| Channel | Behaviour |
|---|---|
| `stable` (default) | Tracks tagged releases — notifies when a newer tag exists |
| `edge` | Tracks the latest commit on `main` — rolling pre-release, rebuilt on every push |
| `off` | Disables all checks and network access |

### Install on the edge channel

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/main/install.sh | bash -s -- --channel edge
```

---

## Automatic checks

A check runs at shell start, throttled by `NIXLPER_UPDATE_CHECK_INTERVAL` (default: once per day).

When offline, the check is skipped silently — the probe is capped by `NIXLPER_UPDATE_TIMEOUT` (default: 2 seconds) and never hangs.

---

## Ongoing work (`nw`)

```bash
nw
```

Fetches the edge pre-release notes from GitHub and prints commits since the last stable tag. Lets you see what is being worked on before the next release.

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_UPDATE_CHANNEL` | `stable` | `stable` / `edge` / `off` |
| `NIXLPER_UPDATE_CHECK` | `true` | Enable/disable automatic checks |
| `NIXLPER_UPDATE_AUTO` | `false` | Auto-install updates (default: notify only) |
| `NIXLPER_UPDATE_CHECK_INTERVAL` | `86400` | Seconds between automatic checks |
| `NIXLPER_UPDATE_TIMEOUT` | `2` | Network probe timeout in seconds |

Configure via `nconf` (`CTRL+X+C`).

---

[← Back to home](index.md)
