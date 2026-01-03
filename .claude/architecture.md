# Nixlper Architecture

## Build Flow
```
src/main/*.sh → build.sh → build/distributions/nixlper-*.tar
```

## Core Modules

### bookmarks.sh
- **Purpose**: Bookmark management
- **Shortcuts**: CTRL+X,D (display), CTRL+X,B (add/remove)
- **Storage**: ~/.nixlper/bookmarks
- **Features**: Quick directory access, list management

### navigation.sh
- **Purpose**: Interactive navigation
- **Shortcuts**: CTRL+X,N (navigate), CTRL+X,U (cd ..)
- **Modes**: tree/flat (NIXLPER_NAVIGATE_MODE)
- **Features**: Subfolder exploration, file opening, size display

### files.sh
- **Purpose**: File and folder operations
- **Commands**: 
  - `cdf FILEPATH`: cd to file's directory
  - `c`: mark current folder
  - `gc`: go to marked folder
  - `cf FILEPATH`: mark current file
  - `gcf`: open marked file in vim
- **Shortcuts**: CTRL+X,E (safe rm folder), CTRL+X,R (safe rm contents)

### processes.sh
- **Purpose**: Process management
- **Commands**: `ik` (interactive kill)
- **Features**: Kill by pattern or port

### users.sh
- **Purpose**: User switching
- **Commands**: `sucd USER` (su - USER and stay in folder)

### macros.sh
- **Purpose**: Command recording and playback
- **Shortcuts**: 
  - CTRL+P: start/stop recording
  - CTRL+X,CTRL+X: play recorded commands
- **Storage**: Uses bash history

### help.sh
- **Purpose**: Help system
- **Shortcuts**: CTRL+X,H
- **Features**: Search help by topic

## Extension Points

### Adding a New Module
1. Create `src/main/new_feature.sh`
2. Define functions with clear naming
3. Add initialization code if needed
4. Build will automatically include it

### Adding New Shortcuts
```bash
# In module initialization or main script
bind -x '"\C-xy": your_function_name'
```

### Adding New Storage
- Create files in ~/.nixlper/
- Follow simple text format (one item per line)
- Load/save with standard bash file operations

## Installation Architecture

### Fresh Install
1. Extract archive to chosen directory (e.g., /opt/nixlper)
2. Run `./nixlper.sh install`
3. Updates ~/.bashrc with source command
4. Creates ~/.nixlper/ directory if needed
5. Ready for next login

### Update
1. Extract new archive over existing installation
2. Run `./nixlper.sh update`
3. Preserves user data in ~/.nixlper/
4. Updates ~/.bashrc if needed

### Uninstall
1. Run `./nixlper.sh uninstall`
2. Removes source command from ~/.bashrc
3. Optionally removes ~/.nixlper/ directory
4. Archive remains for potential reinstall

## Key Design Principles

### Modularity
- Each module focuses on one domain
- Modules can be developed independently
- Build process unifies them

### Simplicity
- No external dependencies
- Plain text storage
- Bash-only implementation

### Safety
- Interactive confirmations (rm -i)
- No dangerous wildcards in history
- Clear command display before execution

### Portability
- Works in Git Bash (Windows)
- Works in Linux/Unix bash
- Minimal environment assumptions

## Data Flow

### Bookmarks
```
User → CTRL+X,B → Add to ~/.nixlper/bookmarks
User → CTRL+X,D → Read from ~/.nixlper/bookmarks → Display
```

### Navigation
```
User → CTRL+X,N → Scan current directory
→ Display numbered list → User selects → Execute cd or vim
```

### Macros
```
User → CTRL+P → Start recording (set flag)
Commands executed → Saved to history
User → CTRL+P again → Stop recording
User → CTRL+X,CTRL+X → Replay from history
```

## Build System Details

### build.sh Responsibilities
1. Set version number
2. Create build/distributions/ directory
3. Concatenate all src/main/*.sh files
4. Add main entry point (nixlper.sh)
5. Create tar archive with version number
6. Clean temporary files

### Distribution Contents
- nixlper.sh (main entry script)
- All module code concatenated
- install/update/uninstall functions
- README.md
- LICENSE

## Future Architecture Considerations
- Plugin system for external modules
- Configuration file support
- Multi-shell support (zsh, fish)
- Automated testing framework
