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

### Quick install (recommended)

The easiest way to install or update Nixlper is to use the install script.
It automatically detects whether Nixlper is already installed and performs a first install or an update accordingly.

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

### Manual install

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

### Uninstall

This is pretty simple, just perform the command below from the install path:
`./nixlper uninstall`

"Sorry that you uninstall it! :("

## Features

### Bookmarks

- `CTRL + X then D`: display existing bookmarks
- `CTRL + X then B`: add or remote existing bookmark for **current** folder

### Files and folders

- `cdf FILEPATH`: Go the folder of the file


- `c`: mark current folder, use `gc` to go this folder from any place
- `cf FILEPATH` : mark file as current, use `gcf` to open it in vim from any place


- `cpcb [FILEPATH]`: copy full path of file to clipboard (defaults to current directory if no argument)
- `cpdcb FILEPATH`: copy full path of directory containing the file to clipboard


- `CTRL + X then E`: display a safe rm command such as `rm -i -rf /tmp/qmt/anyfolder && cd..` to quickly delete current folder and to avoid `rm -rf *` in your bash history
- `CTRL + X then R`: display a safe rm command such as `rm -i -rf /tmp/qmt/anyfolder/* ` to quickly delete current folder contents and to avoid `rm -rf *` in your bash history

### Processes

- `ik`: call interactive kill to kill by pattern or by port

### Users

- `sucd USER`: perform a su - USER and stay in current folder

### Navigation

- `CTRL + X THEN U`: perform a "cd .."
- `CTRL + X THEN N`: display an interactive way to navigate to subfolders and to open files with alias/copy-paste
  (Navigation can use tree or flat mode. "tree" is the default value)

See ```export NIXLPER_NAVIGATE_MODE=tree``` in ~/.bashrc.


- `toggle_navigation_mode`: 
  - toggle items sizes display during navigate action (very useful when your hard drive is full!)
  - Also display permissions for files when option is on

- `fan PATTERN`: execute "find . -iname "*PATTERN*"" then display results like `CTRL + X THEN N` command

### Macros
- `CTRL + P`: start recording
- `CTRL + P, CTRL + P`: stop recording
- `CTRL + X, CTRL + X`: play recorded commands

### Display help

- `CTRL + X then H`: give the ability to search help per topic

### Version and Logo

- `CTRL + X then V`: display the Nixlper logo with version information and git SHA

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
