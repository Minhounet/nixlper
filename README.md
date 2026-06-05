# NIXLPER

This is my personnal helper in Unix environment. I took the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) and tried to apply it in Unix.

## Description

The goal of the bash project is to provide useful Unix commands for various purpose. It takes the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) 
and this is why it contains a lots of key shortcuts.
Now, you can decide to build it by yourself following [next chapter](#prerequisites-for-sh-build) or you can simply download the lastest release from Github.

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

> Throughout this section, `$NIXLPER_EDITOR` refers to the editor used to open files
> (defaults to `vim`, configurable via the `NIXLPER_EDITOR` environment variable).

### Command Palette (Find Action)

The fastest way to discover and run any Nixlper command. It opens an `fzf`-powered,
searchable popup of every available command (with its description, category, keybinding,
and alias) so you can fuzzy-search and execute without remembering exact names.

- `CTRL + X then A` (or `fa`): open the command palette and search commands by name, description, or category

> Requires [`fzf`](https://github.com/junegunn/fzf#installation).

### Bookmarks

- `CTRL + X then D`: display existing bookmarks
- `CTRL + X then B`: add or remove existing bookmark for the **current** folder

### Files and folders

- `cdf FILEPATH`: go to the folder containing the file


- `c`: mark current folder, use `gc` to return to this folder from any place
- `cf FILEPATH`: mark file as current, use `gcf` to open it in `$NIXLPER_EDITOR` from any place


- `cpcb [FILEPATH]`: copy full path of file to clipboard (defaults to current directory if no argument)
- `cpdcb FILEPATH`: copy full path of the directory containing the file to clipboard

  (Clipboard support requires `xclip`, `xsel`, or `pbcopy`.)


- `sn FILEPATH`: snapshot a file into the snapshots area so you can restore it later
- `re [FILEPATH]`: restore a previously snapshotted file. Without an argument, an interactive list of restorable files is shown
- `olf`: open the most recently modified file in the current directory tree with `$NIXLPER_EDITOR`
- `rn FILENAME PATTERN [REPLACEMENT]`: rename a file by removing or replacing a pattern
  (e.g. `rn file_peppa.txt _peppa` → `file.txt`, `rn test-old.txt -old -new` → `test-new.txt`)


- `CTRL + X then E`: display a safe rm command such as `rm -i -rf /tmp/qmt/anyfolder && cd..` to quickly delete the current folder and to avoid `rm -rf *` in your bash history
- `CTRL + X then R`: display a safe rm command such as `rm -i -rf /tmp/qmt/anyfolder/* ` to quickly delete the current folder contents and to avoid `rm -rf *` in your bash history

### Processes

- `ik`: call interactive kill to kill by pattern or by port (port mode requires `netstat`)

### Users

- `sucd USER`: perform a `su - USER` and stay in the current folder

### Navigation

- `CTRL + X THEN U`: perform a "cd .."
- `CTRL + X THEN N`: display an interactive way to navigate to subfolders and to open files with alias/copy-paste
  (Navigation can use tree or flat mode. "tree" is the default value and requires `tree`)

See ```export NIXLPER_NAVIGATE_MODE=tree``` in ~/.bashrc.


- `toggle_navigation_mode`: 
  - toggle items sizes display during the navigate action (very useful when your hard drive is full!)
  - also display permissions for files when the option is on

- `fan PATTERN`: execute `find . -iname "*PATTERN*"` then display the results like the `CTRL + X THEN N` command.
  Each match offers shortcuts to open the file (`vN`), cd into its folder and navigate (`cdfN`), or delete it (`dN`)
- `fag PATTERN`: execute `grep -rn PATTERN .` then display each match with a shortcut (`vN`) to open the file directly at the matching line

### Macros

Record a sequence of commands once and replay it with a single shortcut.

- `CTRL + P` (or `sr`): start recording
- `CTRL + P, CTRL + P` (or `fr`): stop recording (binds the recorded commands to `CTRL + X, CTRL + X`)
- `CTRL + X, CTRL + X`: play the recorded commands
- `CTRL + P, CTRL + L`: re-bind and replay the last recorded macro (persisted across sessions)

### Utilities

- `CTRL + X then O`: open `nixlper.sh` in `$NIXLPER_EDITOR` for quick edits
- `rf`: refresh the current directory (clears the screen and lists its contents; falls back to home if the directory was deleted)
- `ap`: prepend the current path to the `PATH` variable in `~/.bashrc` (if not already present)

### Custom scripts

Any script placed in the custom directory (default `${NIXLPER_INSTALL_DIR}/custom`, configurable via
`NIXLPER_CUSTOM_DIR`) is automatically sourced at login, so you can extend Nixlper with your own
aliases and functions.

### Display help

- `CTRL + X then H`: give the ability to search help per topic (uses `fzf` and `less`)

### Version and Logo

- `CTRL + X then V`: display the Nixlper logo with version information and git SHA

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
