# NIXLPER

> 🚀 **Current version: v2.2.0** — [Release notes](https://github.com/Minhounet/nixlper/releases)
>
> **What's new in v2.2.0:** Adds `nconf` (`CTRL+X+C`), a menu-driven interactive editor for all `NIXLPER_*` settings with automatic `.bashrc` migration to `~/.config/nixlper/nixlper.conf`.
>
> Nixlper evolves constantly. Tagged releases are stable snapshots. Two channels are available: **stable** (default, tagged releases) and **edge** (rolling build of every commit on `main`, not an official release). See [Updates](#updates) for installation commands.

> 🇫🇷 [Version française](README.fr.md)

This is my personal helper in Unix environment. I took the philosophy from [Total Commander](https://www.ghisler.com/accueil.htm) and tried to apply it in Unix.

## 🎉 v2.0.0 — A New Chapter

Version 2.0.0 marks a turning point for the project. What started as a personal collection of bash shortcuts has grown into a structured, properly packaged tool with a real distribution story.

The headline addition is the **command palette** (`CTRL+X+A`): a fuzzy-searchable popup of every available command, with its description, category, keybinding, and alias. You no longer need to remember anything — just open the palette and type. This single feature changes the way the tool is used and discovered, and it is the main reason this release earns a major version bump.

Beyond that, v2.0.0 ships:
- 📦 **RPM and DEB packages** — install via your system package manager, no manual steps needed
- ⚡ **`install.sh`** — a one-liner curl install and self-updating script
- 🔍 **`fag`** — grep across files and jump straight to the matching line in your editor
- 🗂️ **`fan` shortcuts** — delete or `cd` into any search result directly
- ✏️ **Rename-by-pattern** (`rn`) and a **refresh** command (`rf`)
- 💡 A **tips system** that surfaces a new tip at every shell start
- 🛠️ Missing-tool detection at startup so you know exactly what to install

## Description

The goal of the bash project is to provide useful Unix commands for various purposes. It takes the philosophy from [Total Commander](https://www.ghisler.com/accueil.htm)
and this is why it contains a lot of key shortcuts.
You can build it yourself following [next chapter](#prerequisites-for-sh-build) or simply download the latest release from GitHub.

## Architecture

This project consists of multiple modular `.sh` scripts located in `src/main`.
The build process (via `build.sh`) concatenates and packages them into
a single distributable archive. After extraction, the main entry script
`nixlper.sh` orchestrates the internal modules.

This approach allows:
- Easier development and maintenance of individual modules.
- A single installable script for end users.

The build output is found in `build/distributions/`.

## Prerequisites for sh build
You need a bash command line, I personally use [Git bash](https://git-scm.com/downloads). 

## Build with sh

The sh command is simple and straightforward.
```bash
# Execute the command
./build.sh
```
You will have in build/distributions the nixlper-<version>.tar archive.

## Installation

> **Scope overview**
> - **Quick install / Manual install** — current user only: configures `~/.bashrc`.
> - **Quick install `--system` / Manual `install-system`** — all users: writes `/etc/profile.d/nixlper.sh` (requires `sudo`).
> - **RPM / DEB** — all users: same mechanism, managed by the package manager.

### Quick install (recommended)

The easiest way to install or update Nixlper is to use the install script.
It automatically detects whether Nixlper is already installed and performs a first install or an update accordingly.
This method activates nixlper **for the current user only** by adding a block to `~/.bashrc`.

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh | bash
```

Or download and run it manually:

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh
chmod +x install.sh
./install.sh
```

The script will:
- Fetch the latest release from GitHub
- Detect if Nixlper is already installed
- **First install**: ask for an install directory (default `/opt/nixlper`), download, extract, and configure `.bashrc`
- **Update**: download the new version into the existing install directory, preserving your custom scripts

### Quick install — system-wide (all users)

To install for all users, pass `--system`. This requires running as root and writes
`/etc/profile.d/nixlper.sh` and `/etc/nixlper/nixlper.conf` instead of touching `~/.bashrc`.

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh)" -- --system
```

Or download and run manually:

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh
chmod +x install.sh
sudo ./install.sh --system
```

### Manual install

This method also activates nixlper **for the current user only** by adding a block to `~/.bashrc`.

Perform the commands below for the first install:
- Put the archive on any server in the folder you want to install it (for instance **/opt/nixlper**)
- Unpack it using the "tar -xf" command
- Then run ./nixlper.sh install

```bash
mkdir -p /opt/nixlper
# copy archive, /tmp is example
cp /tmp/nixlper*tar /opt/nixlper
cd /opt/nixlper
tar -xf nixlper*.tar
./nixlper.sh install
```

Your .bashrc file will be updated and nixlper will be ready to be used for next login.

### Manual update

For an update just follow the same steps except for last command which will be:
`./nixlper.sh update`

### Manual uninstall

Run the command below from the install directory:

```bash
cd /opt/nixlper
./nixlper.sh uninstall
```

For a system-wide install:

```bash
sudo /opt/nixlper/nixlper.sh uninstall-system
```

### RPM install (RHEL / Fedora / Rocky Linux)

Download the latest `.rpm` from the [GitHub Releases](https://github.com/Minhounet/nixlper/releases) page, then install it:

```bash
# With dnf (recommended — handles dependencies)
sudo dnf install nixlper-*.rpm

# Or with rpm directly
sudo rpm -ivh nixlper-*.rpm
```

To upgrade an existing installation:

```bash
sudo dnf upgrade nixlper-*.rpm
# or
sudo rpm -Uvh nixlper-*.rpm
```

After installation, nixlper is automatically activated for all users via `/etc/profile.d/nixlper.sh` at next login.
System-wide defaults live in `/etc/nixlper/nixlper.conf` (preserved on upgrade).
Per-user overrides go in `~/.config/nixlper/nixlper.conf`.

To remove:

```bash
sudo dnf remove nixlper
# or
sudo rpm -e nixlper
```

### DEB install (Debian / Ubuntu)

Download the latest `.deb` from the [GitHub Releases](https://github.com/Minhounet/nixlper/releases) page, then install it:

```bash
# With apt (recommended — handles dependencies)
sudo apt install ./nixlper_*_all.deb

# Or with dpkg directly
sudo dpkg -i nixlper_*_all.deb
```

To upgrade, simply re-run the install command with the new `.deb` file.

After installation, nixlper is automatically activated for all users via `/etc/profile.d/nixlper.sh` at next login.
System-wide defaults live in `/etc/nixlper/nixlper.conf` (preserved on upgrade).
Per-user overrides go in `~/.config/nixlper/nixlper.conf`.

To remove:

```bash
sudo apt remove nixlper
# or
sudo dpkg -r nixlper
```

## Features

Full command reference, keybindings, and guides are on the **[Nixlper documentation site](https://minhounet.github.io/nixlper/)**.

Quick overview of what's available:

| Category | Highlights |
|---|---|
| **Command palette** | `CTRL+X+A` — fuzzy-search all commands without remembering names |
| **Navigation** | Interactive browser, search by name/content, jump to folders |
| **Bookmarks** | Save and recall frequently used directories |
| **Files & folders** | Snapshot/restore, rename-by-pattern, clipboard, safe delete |
| **Target staging** | Collect and pack files for transfer |
| **Macros** | Record and replay command sequences |
| **SSH connections** | Quick-connect with automatic key push |
| **Configuration** | `nconf` / `CTRL+X+C` — interactive settings editor |
| **Updates** | Stable and edge channels with automatic checks |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
