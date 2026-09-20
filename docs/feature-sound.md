# Sound

> **Play a short pitched tune through the PC speaker.**

> 🇫🇷 [Version française](fr/feature-sound.md)

| Alias | Description |
|---|---|
| `tune` | Play a short pitched tune (`success`, `error`, or `fanfare`) |

---

## Usage

```bash
tune [PRESET]
```

`tune` plays a short pitched melody through the local PC speaker, using the [`beep`](https://github.com/johnath/beep)
utility. `PRESET` is optional and defaults to `success`; available presets are:

- `success` — a short rising arpeggio
- `error` — two short descending low tones
- `fanfare` — three quick high notes followed by a held note

---

## Important: this is a *local speaker* sound, not audio playback

`beep` drives the PC speaker (or `pcspkr` kernel device) of whatever machine actually runs the
command — it does not play audio through your sound card, and it is not routed over the network.

- **Over SSH, this rings on the remote server, not your laptop.** If you `ssh` into a box and run
  `tune`, you generally will not hear anything locally — the tune (if it plays at all) sounds on
  the remote machine's console.
- It requires the `beep` package to be installed (`sudo apt install beep` / `sudo dnf install beep`)
  and PC speaker access: the `pcspkr` kernel module loaded, and permission to write to the
  console/evdev device (some distros restrict this to `root` or a specific group).
- If `beep` is missing or speaker access is denied, `tune` prints an error explaining why —
  it never fails silently.

On a local terminal session (not over SSH) with `beep` installed and speaker access, this works
with no other dependencies — no audio file, no media player.

---

## Example

```bash
$ tune
$ tune error
$ tune fanfare
```

---

## Configuration

Available via `nconf` (`CTRL+X+C`):

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_SOUND_DEFAULT_PRESET` | `success` | Preset played when `tune` is called with no argument |

---

[← Back to home](index.md)
