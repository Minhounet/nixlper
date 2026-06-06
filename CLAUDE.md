# CLAUDE.md — nixlper

## Commit Convention

All commits must follow the gitmoji format:

```
[EMOJI][WORD]|Commit message.
```

- **EMOJI** — the gitmoji character (not the `:code:`)
- **WORD** — short word signifying the commit type (see table below)
- `|` — separator between type and message
- **Commit message** — imperative, concise, ends with a period

### Examples

```
✨feat|Add fuzzy search for command shortcuts.
🐛fix|Resolve null expansion in nixlper.sh.
📝docs|Update installation guide in README.
♻️refactor|Extract key-binding logic into module.
🔧config|Add build.properties defaults.
✅test|Add unit tests for alias resolution.
🔥remove|Delete deprecated total-commander stubs.
⬆️deps|Upgrade bash minimum version requirement.
🚀deploy|Publish v1.4.0 release artifacts.
💥breaking|Drop support for zsh < 5.0.
```

### Gitmoji Reference

| Emoji | Word | Description |
|-------|------|-------------|
| 🎨 | `style` | Improve structure or format of the code |
| ⚡️ | `perf` | Improve performance |
| 🔥 | `remove` | Remove code or files |
| 🐛 | `fix` | Fix a bug |
| 🚑️ | `hotfix` | Critical hotfix |
| ✨ | `feat` | Introduce new features |
| 📝 | `docs` | Add or update documentation |
| 🚀 | `deploy` | Deploy stuff |
| 💄 | `ui` | Add or update UI and style files |
| 🎉 | `init` | Begin a project |
| ✅ | `test` | Add, update, or pass tests |
| 🔒️ | `security` | Fix security or privacy issues |
| 🔐 | `secrets` | Add or update secrets |
| 🔖 | `release` | Release / version tags |
| 🚨 | `lint` | Fix compiler or linter warnings |
| 🚧 | `wip` | Work in progress |
| 💚 | `ci` | Fix CI build |
| ⬇️ | `downgrade` | Downgrade dependencies |
| ⬆️ | `deps` | Upgrade dependencies |
| 📌 | `pin` | Pin dependencies to specific versions |
| 👷 | `build-ci` | Add or update CI build system |
| 📈 | `analytics` | Add or update analytics or tracking code |
| ♻️ | `refactor` | Refactor code |
| ➕ | `add-dep` | Add a dependency |
| ➖ | `rm-dep` | Remove a dependency |
| 🔧 | `config` | Add or update configuration files |
| 🔨 | `script` | Add or update development scripts |
| 🌐 | `i18n` | Internationalization and localization |
| ✏️ | `typo` | Fix typos |
| ⏪️ | `revert` | Revert changes |
| 🔀 | `merge` | Merge branches |
| 📦️ | `package` | Add or update compiled files or packages |
| 👽️ | `api` | Update code due to external API changes |
| 🚚 | `move` | Move or rename resources |
| 📄 | `license` | Add or update license |
| 💥 | `breaking` | Introduce breaking changes |
| 🍱 | `assets` | Add or update assets |
| ♿️ | `a11y` | Improve accessibility |
| 💡 | `comment` | Add or update source code comments |
| 💬 | `text` | Add or update text and literals |
| 🗃️ | `db` | Perform database related changes |
| 🔊 | `log` | Add or update logs |
| 🔇 | `no-log` | Remove logs |
| 🏗️ | `arch` | Make architectural changes |
| 🩹 | `patch` | Simple fix for non-critical issue |
| ⚰️ | `dead` | Remove dead code |
| 🧪 | `test-fail` | Add a failing test |
| 🏷️ | `types` | Add or update types |
| 🌱 | `seed` | Add or update seed files |
| 🚩 | `flag` | Add, update, or remove feature flags |
| 🥅 | `catch` | Catch errors |
| 🗑️ | `deprecate` | Deprecate code needing cleanup |
| 🛂 | `auth` | Work on authorization, roles, permissions |
| 🧐 | `explore` | Data exploration or inspection |
| 🦺 | `validate` | Add or update validation code |
| 🧵 | `thread` | Add or update multithreading or concurrency code |

### API Reference

Gitmoji list sourced from:
```
https://raw.githubusercontent.com/carloscuesta/gitmoji/master/packages/gitmojis/src/gitmojis.json
```
