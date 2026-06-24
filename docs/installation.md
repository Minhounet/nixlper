# Installation

## Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh | bash
```

Open a new shell — nixlper is active immediately.

This installs for **the current user only** (adds a block to `~/.bashrc`).

---

## System-wide install (all users)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh)" -- --system
```

Writes `/etc/profile.d/nixlper.sh` and `/etc/nixlper/nixlper.conf`. No `~/.bashrc` changes.

---

## RPM (RHEL / Fedora / Rocky Linux)

Download the `.rpm` from [GitHub Releases](https://github.com/Minhounet/nixlper/releases), then:

```bash
sudo dnf install nixlper-*.rpm
```

Nixlper activates for all users at next login via `/etc/profile.d/nixlper.sh`.

```bash
# Upgrade
sudo dnf upgrade nixlper-*.rpm

# Remove
sudo dnf remove nixlper
```

---

## DEB (Debian / Ubuntu)

Download the `.deb` from [GitHub Releases](https://github.com/Minhounet/nixlper/releases), then:

```bash
sudo apt install ./nixlper_*_all.deb
```

```bash
# Remove
sudo apt remove nixlper
```

---

## Manual install

```bash
# Build from source (requires bash + dos2unix)
./build.sh

# Install
mkdir -p /opt/nixlper
cp build/distributions/nixlper*.tar /opt/nixlper
cd /opt/nixlper && tar -xf nixlper*.tar
./nixlper.sh install
```

```bash
# Update
./nixlper.sh update

# Uninstall
./nixlper.sh uninstall
```

---

## Update channels

| Channel | Command |
|---|---|
| `stable` (default) | `curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/main/install.sh \| bash` |
| `edge` (rolling) | `curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/main/install.sh \| bash -s -- --channel edge` |

➜ [More about updates](feature-updates.md)

---

## Prerequisites

- **bash ≥ 4.0**
- **`fzf`** — required for command palette, navigation, SSH picker, config editor
  ```bash
  # macOS
  brew install fzf
  # Fedora/RHEL
  dnf install fzf
  # Debian/Ubuntu
  apt install fzf
  ```
- **`tree`** — optional, for tree navigation mode (`CTRL+X+N`)
- **`xclip` / `xsel` / `pbcopy`** — optional, for clipboard commands

Nixlper reports any missing tools at shell start.

---

[← Back to home](index.md)
