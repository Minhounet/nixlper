# Nixlper-Specific Skills
## sense of humor
I believe genuinely that we can do work seriously but still make jokes. So I am not against puns or play of words in my code as long that everything works fine. For example jokes can be sometimes in the comments or in the log.

## Modular Bash Development
- Create reusable bash functions
- Manage environment variables (NIXLPER_*)
- Implement keyboard shortcuts with bind
- Handle readline bindings and key sequences

## Project Patterns

### Bookmark Pattern
- Storage in ~/.nixlper/ files
- Format: one path per line
- Usage: mark locations for quick access

### Interactive Navigation Pattern
- Numbered display + selection
- Tree or flat mode support
- Aliases for quick access
- Copy-paste friendly output

### Safety Pattern
- Always use -i flag for rm commands
- Provide confirmation prompts
- Display full commands before execution
- Avoid dangerous `rm -rf *` in history

### Keyboard Binding Pattern
```bash
# Multi-key sequences using CTRL+X as prefix
bind -x '"\C-xd": function_name'
# Recording state with global variables
# Macro playback from history
```

## Module Structure
Each module in src/main/ should:
1. Define functions with clear names
2. Use proper error handling
3. Be testable independently
4. Integrate seamlessly in build

## Testing Approach
- Test in Git Bash environment
- Verify Linux/Unix compatibility
- Validate integration in final build
- Check keyboard bindings work correctly
- Test with different terminal emulators

## Build Process
1. Individual modules in src/main/
2. build.sh concatenates all .sh files
3. Creates versioned tar archive
4. Output in build/distributions/

## Release Workflow
- Increment version in build.sh
- Tag with git tag v*.*.* 
- Generate archive with ./build.sh
- Test installation from archive
- Upload to GitHub releases

## Common Development Tasks

### Adding a New Feature
1. Create new module in src/main/
2. Follow naming conventions
3. Add keyboard binding if needed
4. Update help system (CTRL+X,H)
5. Test individually
6. Test with shellcheck and Refactor if not risky
7. Build and test complete package
8. Tell what was not really tested and need attention

### Non exposed functions
1. add _ for functions only used internally

### Adding a Keyboard Shortcut
1. Define function in appropriate module
2. Add bind command in initialization
3. Document in README.md
4. Update help system

### Storage and Configuration
- User data: ~/.nixlper/
- Configuration: environment variables in ~/.bashrc
- No config files needed (simplicity principle)
