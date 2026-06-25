# Installation

> 🇬🇧 [English version](../installation.md)

## Installation rapide (recommandée)

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh | bash
```

Ouvrez un nouveau shell — nixlper est actif immédiatement.

Installe **pour l'utilisateur courant uniquement** (ajoute un bloc dans `~/.bashrc`).

---

## Installation système (tous les utilisateurs)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh)" -- --system
```

Écrit `/etc/profile.d/nixlper.sh` et `/etc/nixlper/nixlper.conf`. Aucune modification de `~/.bashrc`.

---

## RPM (RHEL / Fedora / Rocky Linux)

Téléchargez le `.rpm` depuis [GitHub Releases](https://github.com/Minhounet/nixlper/releases), puis :

```bash
sudo dnf install nixlper-*.rpm
```

Nixlper s'active pour tous les utilisateurs à la prochaine connexion via `/etc/profile.d/nixlper.sh`.

```bash
# Mettre à jour
sudo dnf upgrade nixlper-*.rpm

# Supprimer
sudo dnf remove nixlper
```

---

## DEB (Debian / Ubuntu)

Téléchargez le `.deb` depuis [GitHub Releases](https://github.com/Minhounet/nixlper/releases), puis :

```bash
sudo apt install ./nixlper_*_all.deb
```

```bash
# Supprimer
sudo apt remove nixlper
```

---

## Installation manuelle

```bash
# Compiler depuis les sources (nécessite bash + dos2unix)
./build.sh

# Installer
mkdir -p /opt/nixlper
cp build/distributions/nixlper*.tar /opt/nixlper
cd /opt/nixlper && tar -xf nixlper*.tar
./nixlper.sh install
```

```bash
# Mettre à jour
./nixlper.sh update

# Désinstaller
./nixlper.sh uninstall
```

---

## Canaux de mise à jour

| Canal | Commande |
|---|---|
| `stable` (défaut) | `curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/main/install.sh \| bash` |
| `edge` (continu) | `curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/main/install.sh \| bash -s -- --channel edge` |

➜ [En savoir plus sur les mises à jour](feature-updates.md)

---

## Prérequis

- **bash ≥ 4.0**
- **`fzf`** — requis pour la palette de commandes, la navigation, le sélecteur SSH et l'éditeur de configuration
  ```bash
  # macOS
  brew install fzf
  # Fedora/RHEL
  dnf install fzf
  # Debian/Ubuntu
  apt install fzf
  ```
- **`tree`** — optionnel, pour le mode de navigation arborescente (`CTRL+X+N`)
- **`xclip` / `xsel` / `pbcopy`** — optionnel, pour les commandes de presse-papier

Nixlper signale les outils manquants au démarrage du shell.

---

[← Retour à l'accueil](index.md)
