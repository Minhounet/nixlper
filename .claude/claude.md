# Nixlper - Project Context

## Overview
Nixlper is a bash helper inspired by Total Commander for Unix/Linux environments.
Modular architecture with scripts in src/main/, compiled into a single executable.

## Project Philosophy
- Keyboard shortcuts inspired by Total Commander
- Modular scripts but unified distribution
- Simple installation (install/update/uninstall)
- "Safe" approach (rm -i, confirmations)

## Project Structure
- `src/main/` : individual bash modules
- `build.sh` : concatenation and packaging
- `build/distributions/` : distribution archives
- `internal/` : internal utilities
- `documentation/` : additional docs

## Code Conventions
- Pure bash scripts, Git Bash compatible
- Naming: snake_case for functions
- Comments in English in code
- Each module must be standalone but integrable

## Development Workflows
- show plan before coding
- Test modules individually in src/main/
- Build with ./build.sh before commit
- Installation tests in /opt/nixlper

## Key Technical Decisions
- Build by concatenation (distribution simplicity)
- No external dependencies required
- Installation modifies ~/.bashrc
- Supports tree/flat mode for navigation

## Key Features
- Bookmarks: CTRL+X,D (display) and CTRL+X,B (add/remove)
- Navigation: CTRL+X,N (interactive subfolder/file navigation)
- File operations: cdf, cf, c, gc, gcf
- Safe deletion: CTRL+X,E and CTRL+X,R
- Process management: ik (interactive kill)
- Macros: CTRL+P (record), CTRL+X,CTRL+X (play)
- Help: CTRL+X,H (search by topic)

## Environment Variables
- `NIXLPER_NAVIGATE_MODE`: tree|flat (navigation display mode)
- Installation path typically: /opt/nixlper or user-chosen directory
