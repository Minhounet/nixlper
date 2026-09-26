# PowerShell (preview)

> **Know bash but stuck in PowerShell? Type `grep -rn`, `ls -la`, `rm -rf`, `tail -f` and they just work, plus nixlper's bookmarks and command palette on the same `CTRL+X` shortcuts.**

> 🇫🇷 [Version française](fr/feature-powershell.md)

> ⚠️ **Preview.** This is a first cut of the PowerShell port. It covers the bash-compat commands, bookmarks and the command palette; the other nixlper features are still bash-only. Tested on PowerShell 7 on Linux; written to run on Windows PowerShell 5.1 and PowerShell 7 on Windows, but not yet tried there. Feedback is welcome.

| Shortcut | Alias | Description |
|---|---|---|
| `CTRL+X+A` | `fa` | Command palette: search and run any nixlper command |
| `CTRL+X+D` | `bd` | Display saved bookmarks and jump to one |
| `CTRL+X+B` | `bm` | Add or remove a bookmark for the current folder |
| — | `grep` | Search text: `-i -v -n -r -l -c -w -x -o -F -E -e --include` |
| — | `head` / `tail` | First / last lines: `-n N`, `-N`, `tail -n +N`, `tail -f` |
| — | `wc` | Count lines / words / bytes: `-l -w -c` |
| — | `ls` | List: `-a -l -R -t -S -r -1 -d` |
| — | `rm` / `cp` / `mv` | Remove / copy / move: `-r -f -i -v` |
| — | `touch` / `which` / `export` | Create files, locate commands, set environment variables |

---

## Install

Nixlper for PowerShell is a regular PowerShell module, shipped as `nixlper-powershell-vX.Y.Z.zip` with each [GitHub release](https://github.com/Minhounet/nixlper/releases) (starting with the first release after this preview).

### From the release zip (recommended)

Download the zip, then in PowerShell (adjust the file name):

```powershell
$zip = "$HOME\Downloads\nixlper-powershell-vX.Y.Z.zip"
# Windows marks downloaded files as coming from the internet; without this the module is refused.
# (Windows only: skip this line on Linux/macOS.)
Unblock-File -Path $zip
# Extract into your personal modules folder (the first PSModulePath entry, for PowerShell 7 and 5.1 alike).
Expand-Archive -Path $zip -DestinationPath ($env:PSModulePath -split [IO.Path]::PathSeparator)[0] -Force
# Load it in every new session.
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Add-Content -Path $PROFILE -Value 'Import-Module Nixlper'
```

Open a new PowerShell window. To upgrade later, repeat the first three commands with the new zip (`-Force` replaces the old files).

### From a clone of the repository

To try the latest code before it is released:

```powershell
git clone https://github.com/Minhounet/nixlper.git $HOME\nixlper
Add-Content -Path $PROFILE -Value 'Import-Module $HOME\nixlper\src\main\powershell\Nixlper\Nixlper.psd1'
```

If script execution is blocked in either case, allow local scripts once with
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

[`fzf`](https://github.com/junegunn/fzf#installation) is optional but recommended (`winget install fzf`): with it, the palette and the bookmark picker become live fuzzy filters.

---

## Bash-style commands

PowerShell already has `ls`, `rm`, `cp` and `mv`, but they are aliases for PowerShell commands, so `ls -la` or `rm -rf build` fail with *"A parameter cannot be found"*. Nixlper replaces them (and adds `grep`, `head`, `tail`, `wc`, `touch`, `which`, `export`) with versions that understand the usual bash flags. Everything is built on PowerShell and .NET, so no extra program is needed.

```powershell
grep -rn TODO src --include=*.java     # recursive, line numbers, only .java files
grep -i 'error\|warn' app.log          # bash-style alternation works (GNU basic regex rules)
Get-Process | grep -w pwsh             # grep the text you would see on screen
tail -f app.log                        # follow a growing log
ls -1t | head -n 5                     # 5 most recently modified names
ls | wc -l                             # number of items
rm -rf build
cp -r src backup
export JAVA_HOME=C:\tools\jdk-21
```

**Your PowerShell habits keep working.** When a command is called with PowerShell parameters (`ls -Recurse`, `rm -Force`, `cp -Destination x`), nixlper passes it unchanged to the original PowerShell command. Scripts that pipe files into them (`Get-ChildItem *.tmp | rm`) work too.

**When is it active?** By default only on Windows. On Linux and macOS the real tools already exist. On Windows, a command is skipped when a real executable with the same name is on your `PATH` (for example from Git for Windows or uutils), because the real tool is better than an emulation. Set `NIXLPER_BASH_COMPAT` to change this (see below).

**Known differences with bash:**
- PowerShell removes a bare `--` before nixlper sees it. To grep for a pattern that starts with a dash, use `grep -e -x`.
- `$VAR` is a PowerShell variable. Environment variables are `$env:VAR`, e.g. `export PATH="$env:PATH;C:\tools"`.
- Regular expressions are .NET regexes with GNU-style translation (`\|`, `\(`, `[[:digit:]]`, `\<`, `\>`). Rare GNU-only constructs such as back-references in basic mode may behave differently.
- `ls` returns file objects (displayed as a detailed listing) so you can pipe them to other PowerShell commands. Use `ls -1` for plain names.
- `grep` context options (`-A`, `-B`, `-C`) are not supported yet.

---

## Bookmarks

Same behaviour as the [bash bookmarks](feature-bookmarks.md):

- `CTRL+X+B` (or `bm`) bookmarks the current folder. You are asked for a name; the folder's name is the default. Run it again in a bookmarked folder to remove the bookmark.
- `CTRL+X+D` (or `bd`) lists bookmarks and jumps to one. With `fzf`, type digits to jump to a numbered entry or letters to fuzzy-filter. Without `fzf`, type the number.
- Each bookmark also becomes a command: type its name to jump there. A bookmark is never allowed to hide an existing command.

The bookmarks file uses **the same format as bash**, so one file can serve both shells. On Linux/macOS PowerShell it is shared with bash by default (`~/.local/share/nixlper/bookmarks`). On Windows, point `NIXLPER_BOOKMARKS_FILE` at your bash file only if both shells use the same kind of path. Git Bash writes `/c/Users/...`, which PowerShell cannot open.

---

## Command palette

`CTRL+X+A` (or `fa`) lists every nixlper command available in the session, with its shortcut, category and description, and runs the one you pick. Commands that need arguments (`grep`, `cp`...) ask for them before running. Commands are discovered from the same `@cmd-palette` annotations as the bash version.

---

## Keyboard shortcuts

The shortcuts are PSReadLine chords: press `CTRL+X`, release, then press `CTRL+A`, `CTRL+D` or `CTRL+B`. Each one replaces the current line with the command and runs it.

> On Windows, PSReadLine's default edit mode uses `CTRL+X` for **Cut**. Binding the nixlper chords turns `CTRL+X` into a prefix key, so it no longer cuts. If you rely on it, set `NIXLPER_PS_KEYBINDINGS=false` and use the aliases (`fa`, `bd`, `bm`) instead.

---

## Configuration

Settings are environment variables. Set them in `$PROFILE` **before** the `Import-Module` line:

```powershell
$env:NIXLPER_BASH_COMPAT = 'true'
Import-Module $HOME\nixlper\src\main\powershell\Nixlper\Nixlper.psd1
```

| Variable | Default | Description |
|---|---|---|
| `NIXLPER_BASH_COMPAT` | `auto` | `auto`: bash-style commands on Windows only, skipping names that exist as real executables. `true`: always, for every command. `false`: never. |
| `NIXLPER_BOOKMARKS_FILE` | `~/.local/share/nixlper/bookmarks` | Bookmarks file (bash format) |
| `NIXLPER_BOOKMARKS_FUZZY` | `true` | Use `fzf` for the bookmark picker when it is installed |
| `NIXLPER_PS_KEYBINDINGS` | `true` | Bind the `CTRL+X` chords |

`Remove-Module Nixlper` puts everything back: PowerShell's original `ls`/`rm`/`cp`/`mv` and no bookmark commands.
