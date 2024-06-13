# NIXLPER

This is my personnal helper in Unix environment. I took the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) and tried to apply it in Unix.

## Table of Contents

- [Description](#description)
- [Prerequisites for sh build](#prerequisites-for-sh-build)
- [Build with sh](#build-with-sh)
- [Installation](#installation)
- [Features](#features)
  - [Bookmarks](#bookmarks)
  - [Files and folders](#files-and-folders)
  - [Processes](#processes)
  - [Users](#users)
  - [Navigation](#navigation)
- [License](#license)

## Description

The goal of the bash project is to provide useful Unix commands for various purpose. It takes the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) 
and this is why it contains a lots of key shortcuts.

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

- Put the archive on any server in the folder you want to install it (for instance **/opt/nixlper**)
- Unpack it using the "tar -xf" command
- Then run ./nixlper-<version>.sh install

```bash
mkdir -p /opt/nixlper
# copy archive, /tmp is example
cp /tmp/nixlper*tar /opt/nixlper
cd /opt/nixlper
tar -xf nixlper*.tar
./nixlper.sh install
```

Your .bashrc file will be updated and nixlper will be ready to be used for next login.

## Features

### Bookmarks

- `CTRL + X then D`: display existing bookmarks
- `CTRL + X then B`: add or remote existing bookmark for **current** folder

### Files and folders

- `cdf FILEPATH`: Go the folder of the file


- `c`: mark current folder, use `gc` to go this folder from any place
- `cf FILEPATH` : mark file as current, use `gcf` to open it in vim from any place


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

- `fan PATTERN`: execute "find . -iname "*PATTERN*"" then display results like `CTRL + X THEN N` command

### Display help

- `CTRL + X then H`: give the ability to search help per topic

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
