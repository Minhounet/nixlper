---
name: nixlper-packaging
description: How nixlper is built and installed — build.sh concatenation and annotation preservation, manual tar install, RPM and native DEB packaging, the /etc and ~/.config config precedence chain, install paths per method, and the edge/stable update channel plumbing. Load before touching build*.sh, install.sh, packaging/, the install/update/uninstall code in nixlper.sh, or config-loading order.
---

# Building, packaging and installing nixlper

## Build flow
```
src/main/bash/*.sh → build.sh → build/distributions/nixlper-*.tar
                              → build-rpm.sh → ~/rpmbuild/RPMS/noarch/nixlper-*.rpm
                              → build-deb.sh → build/distributions/nixlper_*_all.deb
src/main/powershell/Nixlper → build-ps.sh → build/distributions/nixlper-powershell-*.zip  (see nixlper-powershell skill)
```
`build.sh` concatenates every `src/main/bash/function*.sh` into `nixlper.sh`, strips comments, writes a `version` file
(`VERSION:` tag or SHA, plus full `COMMIT:` SHA for the edge channel) and tars it. Requires `dos2unix`. It wipes
`build/distributions` first.

**Annotation preservation.** The strip step keeps every `# @...` line generically
(`sed '/^#[[:space:]]*@/!{/^#.*/d}'`). Never replace this with a whitelist: a missing annotation is invisible to the
runtime palette parser, breaking packaged installs while the dev tree still works.

Versions everywhere come from `git describe --tags --exact-match HEAD`, else the short SHA (`0~<sha>` for DEB).

## Manual install (tar, any Unix)
```bash
bash build.sh
mkdir -p /opt/nixlper && tar -xf build/distributions/nixlper-*.tar -C /opt/nixlper
cd /opt/nixlper && ./nixlper.sh install    # adds `source /opt/nixlper/nixlper.sh` to ~/.bashrc
./nixlper.sh update | uninstall            # update keeps user data; uninstall removes the ~/.bashrc block
```
`install.sh` downloads a release (`--channel stable|edge`, `--yes`, `--system` for a root install writing
`/etc/nixlper/nixlper.conf` via `_i_install_system` and `/etc/profile.d/nixlper.sh`) and aborts cleanly offline.

## Config precedence (lowest → highest)
```
/etc/nixlper/nixlper.conf  <  ~/.bashrc exports (legacy)  <  ~/.config/nixlper/nixlper.conf
```
- System confs use `${VAR:-default}` so they never override an already-set value.
- `~/.config/nixlper/nixlper.conf` is created at install by `_nconf_create_user_conf` with `NIXLPER_INSTALL_DIR` set
  and every other setting commented out; `nconf` (CTRL+X+C) edits it and offers to migrate old
  `export NIXLPER_*` lines out of `~/.bashrc`.
- Without `/etc/nixlper/nixlper.conf` (manual install) paths fall back to `$NIXLPER_INSTALL_DIR/…`
  (`.nixlper_bookmarks`, `snapshots/`, `custom/`, `broadcast_message`, …). RPM/DEB put per-user data under
  `~/.local/share/nixlper/` and `~/.config/nixlper/`, and the admin notice in `/etc/nixlper/broadcast_message`.
- The setting list and defaults live in `_NIXLPER_CONFIG_VARS`; the three templates (user, `_i_install_system`,
  `packaging/shared/nixlper.conf`) must list every one — `scripts/check-feature-completeness.sh` enforces it.
- `NIXLPER_LOADED` guards against double initialisation when both `~/.bashrc` and profile.d source nixlper.

## RPM (RHEL/Fedora/Rocky — needs rpm-build)
`bash build-rpm.sh` (add `--verbose` to see rpmbuild's `set -x` scriptlet trace, quiet by default). It removes old
`nixlper-*.rpm`/`.src.rpm` from `~/rpmbuild` first. Spec `packaging/rpm/nixlper.spec`:
- `BuildArch: noarch`, `Requires: bash >= 4.0`, `Recommends: vim, tree`; `%post`/`%preun` empty.
- `/etc/nixlper/nixlper.conf` is `%config(noreplace)` (admin edits survive upgrades).
- `/etc/profile.d/nixlper.sh` (one line: `source /usr/share/nixlper/nixlper.sh`) is not `%config`: always replaced.
- User data is created on first login, never owned by the package.
```bash
dnf install nixlper-*.noarch.rpm | dnf upgrade … | dnf remove nixlper   # remove leaves user data alone
```

## DEB (native, dpkg-deb)
`bash build-deb.sh` → `build/distributions/nixlper_<version>_all.deb`. Same shared sources as RPM
(`packaging/shared/nixlper.conf`, `packaging/shared/nixlper-profile.d.sh`). Only `/etc/nixlper/nixlper.conf` is in
`DEBIAN/conffiles`; profile.d is not, so it is replaced on upgrade and removed by `dpkg -r`.

## Update channels (`functions_update.sh`)
`NIXLPER_UPDATE_CHANNEL`: `stable` compares `VERSION:` with GitHub `releases/latest`; `edge` compares the full
`COMMIT:` SHA with the `target_commitish` of the rolling `edge` pre-release (built by
`.github/workflows/publish_edge_on_push.yml`, which skips release commits; `create_release_on_tag.yml` ignores the
`edge` tag); `off`. Network use is gated by `_i_is_online` (time-boxed curl) and startup checks are throttled by
`NIXLPER_UPDATE_CACHE_FILE`; `nu` / CTRL+X+W bypasses the throttle. Details: `INTERNALS.md` → "Update detection".

## Checklist after packaging changes
`bash build.sh`, extract and `./nixlper.sh install` in a scratch HOME; `bash build-rpm.sh` / `bash build-deb.sh` when
the tools exist (say so if they don't); test in Git Bash and Linux where possible.
