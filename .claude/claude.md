# Nixlper - Project Context

## Project Overview
Nixlper is a bash helper inspired by Total Commander for Unix/Linux environments. Provides keyboard-driven file navigation, bookmarks, macros, and process management.

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
│   └── functions_*.sh      # Feature modules
├── build.sh                # Build script (concatenation + packaging)
└── .claude/                # AI context files
```

---

## Features

All features are exposed through:
- **Aliases**: Short commands (e.g., `fa`, `ik`, `c`, `cf`)
- **Keybindings**: CTRL+X combinations (e.g., CTRL+X+A, CTRL+X+D)

Features are automatically discovered via `@cmd-palette` annotations in the code.

---

## Code Conventions

### Naming
- **Functions**: `snake_case`
- **Internal functions**: Prefix with `_` (e.g., `_i_log_as_error`)
- **Environment variables**: `NIXLPER_*` prefix

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

### Safety Patterns
- Always use `-i` flag for rm commands
- Provide confirmation prompts
- Display commands before execution

---

## Development Workflow

### Before Coding
1. Show plan/outline to user
2. Discuss approach and architecture

### Development
1. Modify modules in `src/main/bash/`
2. Test modules individually
3. Follow naming conventions
4. Add @cmd-palette annotations for user commands

### Before Commit
1. Build with `./build.sh`
2. Test installation
3. Verify keyboard bindings work

---

## Adding New Features

### New Feature
1. **If related to existing module** (e.g., clipboard, navigation, files):
   - Add to existing `functions_*.sh` file
   - Example: clipboard features → `functions_clipboard.sh`

2. **If completely new domain**:
   - Create new `src/main/bash/functions_feature_name.sh`

3. For both cases:
   - Define functions with clear names (use `_` prefix for internal)
   - Add @cmd-palette annotations for user-facing commands
   - Build will automatically include it

### New Keyboard Shortcut
```bash
# In _i_load_bindings() function in nixlper.sh
bind -x '"\C-x\C-y": your_function_name'  # CTRL+X then Y
```

---

## Build & Installation

### Build
`build.sh` concatenates all `src/main/bash/function*.sh` files, merges with `nixlper.sh`, and creates `nixlper-VERSION.tar` in `build/distributions/`

### Install/Update/Uninstall
```bash
./nixlper.sh install    # Updates ~/.bashrc, creates ~/.nixlper/
./nixlper.sh update     # Preserves user data
./nixlper.sh uninstall  # Removes from ~/.bashrc
```

---

## Environment Variables

Set in `~/.bashrc` after installation:
- `NIXLPER_INSTALL_DIR`: Installation directory
- `NIXLPER_NAVIGATE_MODE`: tree|flat
- `NIXLPER_EDITOR`: Editor to use (default: vim)

---

## Testing Checklist

- [ ] Test in Git Bash and Linux
- [ ] Validate keyboard bindings
- [ ] Run shellcheck if safe
- [ ] Test build and installation
