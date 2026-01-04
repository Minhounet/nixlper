# Nixlper - Complete Project Context

## Project Overview
Nixlper is a bash helper inspired by Total Commander for Unix/Linux environments. It provides keyboard-driven file navigation, bookmarks, macros, and process management through a modular bash architecture.

**Philosophy:**
- Keyboard shortcuts inspired by Total Commander
- Modular development, unified distribution
- Simple installation (install/update/uninstall)
- Safety-first approach (confirmations, rm -i)

**Build Flow:**
```
src/main/bash/*.sh → build.sh → build/distributions/nixlper-*.tar
```

---

## Project Structure

```
nixlper/
├── src/main/bash/          # Individual bash modules
│   ├── nixlper.sh          # Main entry point
│   ├── functions_*.sh      # Feature modules
│   └── ...
├── src/main/help/          # Help documentation files
├── build.sh                # Build script (concatenation + packaging)
├── build/distributions/    # Distribution archives
└── .claude/                # AI context files
```

---

## Core Modules & Features

### Bookmarks (`functions_bookmarks.sh`)
- **CTRL+X+D**: Display bookmarks with aliases
- **CTRL+X+B**: Add/remove bookmark for current folder
- **Storage**: `~/.nixlper/bookmarks`
- **Pattern**: Dynamic aliases (e.g., `projects_alias`)

### Navigation (`functions_navigation.sh`)
- **CTRL+X+N**: Interactive folder/file navigation
- **CTRL+X+U**: Go up one directory
- **Modes**: tree/flat (set by `NIXLPER_NAVIGATE_MODE`)
- **Features**: Numbered selection, dynamic n1/v1 aliases
- **Commands**: `fan` (find and navigate), `toggle_navigation_mode`

### Files & Folders (`functions_files_and_folders.sh`)
- **c**: Mark current folder (use `gc` to return)
- **cf FILE**: Mark file as current (use `gcf` to open)
- **cdf FILE**: cd to file's directory
- **sn FILE**: Snapshot file to snapshots area
- **re [FILE]**: Restore file from snapshots
- **CTRL+X+E**: Display safe rm command for current folder
- **CTRL+X+R**: Display safe rm command for folder contents

### Clipboard (`functions_clipboard.sh`)
- **cpcb [FILE]**: Copy full file path to clipboard
- **cpdcb FILE**: Copy directory path to clipboard

### Processes (`functions_processes.sh`)
- **ik**: Interactive kill by pattern or port

### Macros (`functions_macros.sh`)
- **CTRL+P**: Start recording bash commands
- **CTRL+P+CTRL+P**: Stop and save recording
- **CTRL+P+CTRL+L**: Replay last recorded macro
- **Aliases**: `sr` (start recording), `fr` (finalize recording)
- **Storage**: Uses bash history with markers

### Users (`functions_users.sh`)
- **sucd USER**: Switch user and maintain current directory

### Help & Version (`functions_help.sh`, `functions_version.sh`)
- **CTRL+X+H**: Interactive help search (uses fzf)
- **CTRL+X+V**: Display nixlper logo and version

### Command Palette (`functions_command_palette.sh`)
- **fa** or **CTRL+X+A**: Search and execute commands (IntelliJ-style Find Action)
- **Features**: Dynamic command discovery via @cmd-palette annotations
- **Pattern**: Self-documenting commands with inline metadata

### Utilities
- **ap**: Prepend current path to PATH in .bashrc
- **CTRL+X+O**: Open nixlper.sh in editor

---

## Code Conventions

### Naming
- **Functions**: `snake_case`
- **Internal functions**: Prefix with `_` (e.g., `_i_log_as_error`)
- **Environment variables**: `NIXLPER_*` prefix
- **Dynamic aliases**: `n1`, `n2`, `v1`, `v2` (navigation), bookmark names

### Structure
- Pure bash scripts, Git Bash compatible
- Comments in English
- Each module must be standalone but integrable
- Use shellcheck for validation

### Safety Patterns
- Always use `-i` flag for rm commands
- Provide confirmation prompts
- Display full commands before execution
- Avoid dangerous `rm -rf *` in history

### Command Palette Annotations
Mark user-facing commands with:
```bash
# @cmd-palette
# @description: Brief description
# @category: Category name
# @keybind: CTRL+X+D (optional)
# @alias: shortcut (optional)
function command_name() { ... }
```

---

## Development Workflow

### Before Coding
1. Show plan/outline to user
2. Discuss approach and architecture

### Development
1. Create/modify modules in `src/main/bash/`
2. Test modules individually
3. Follow naming conventions
4. Add command palette annotations for user commands
5. Run shellcheck if safe to refactor

### Before Commit
1. Build with `./build.sh`
2. Test installation in `/opt/nixlper` or test directory
3. Verify keyboard bindings work
4. Check both Git Bash and Linux compatibility

---

## Adding New Features

### New Module
1. Create `src/main/bash/functions_feature_name.sh`
2. Define functions with clear names (use `_` prefix for internal)
3. Add @cmd-palette annotations for user-facing commands
4. Add initialization code if needed
5. Build will automatically include it

### New Keyboard Shortcut
```bash
# In _i_load_bindings() function in nixlper.sh
bind -x '"\C-x\C-y": your_function_name'  # CTRL+X then Y
```

### New Storage
- Create files in `~/.nixlper/` or `${NIXLPER_INSTALL_DIR}/`
- Use simple text format (one item per line)
- Load/save with standard bash file operations

---

## Build & Installation

### Build Process
1. `build.sh` concatenates all `src/main/bash/function*.sh` files
2. Merges with `nixlper.sh` main script
3. Removes comment headers
4. Creates versioned tar: `nixlper-VERSION.tar`
5. Output in `build/distributions/`

### Installation
1. Extract archive to chosen directory (e.g., `/opt/nixlper`)
2. Run `./nixlper.sh install`
3. Updates `~/.bashrc` with source command and environment variables
4. Creates `~/.nixlper/` directory if needed
5. Ready after next login or `source ~/.bashrc`

### Update
1. Extract new archive over existing installation
2. Run `./nixlper.sh update`
3. Preserves user data in `~/.nixlper/`

### Uninstall
1. Run `./nixlper.sh uninstall`
2. Removes source command from `~/.bashrc`
3. Optionally removes `~/.nixlper/` directory

---

## Key Technical Decisions

- **Build by concatenation**: Simplifies distribution (single file)
- **No external dependencies**: Pure bash (except optional: fzf, tree, xclip)
- **Installation modifies ~/.bashrc**: Auto-loads on shell startup
- **Dynamic command discovery**: @cmd-palette annotations enable self-documenting code
- **Modular architecture**: Each feature in separate file during development
- **Plain text storage**: Simple, grep-able, version-controllable

---

## Environment Variables

After installation, these are set in `~/.bashrc`:
- `NIXLPER_INSTALL_DIR`: Installation directory
- `NIXLPER_BOOKMARKS_FILE`: Path to bookmarks file
- `NIXLPER_LAST_MACRO_BINDING_FILE`: Path to last macro binding
- `NIXLPER_NAVIGATE_MODE`: tree|flat (navigation display mode)
- `NIXLPER_EDITOR`: Editor to use (default: vim)
- `NIXLPER_DISPLAY_LENGTH_IN_NAVIGATE`: 0|1 (show size/permissions in navigate)

---

## Testing Checklist

- [ ] Test in Git Bash environment
- [ ] Verify Linux/Unix compatibility
- [ ] Validate integration in final build
- [ ] Check keyboard bindings work correctly
- [ ] Test with different terminal emulators
- [ ] Run shellcheck on modified files
- [ ] Test installation/update/uninstall flow
