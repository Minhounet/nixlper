# Nixlper — Gestion de fichiers pilotée au clavier sous Unix

Nixlper apporte les raccourcis clavier style [Total Commander](https://www.ghisler.com/accueil.htm) à votre shell Unix.
Pas d'interface graphique — juste votre terminal.

> 🇬🇧 [English version](../index.md)

> 🚀 **Version actuelle : v2.2.0** — [Notes de version](https://github.com/Minhounet/nixlper/releases)

---

## Installer en une ligne

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh | bash
```

Ouvrez un nouveau shell. C'est tout.

➜ [Guide d'installation complet](installation.md)

---

## Fonctionnalités

| Objectif | Page |
|---|---|
| 🔍 Découvrir et lancer n'importe quelle commande instantanément | [Palette de commandes](feature-command-palette.md) |
| 📂 Naviguer dans le système de fichiers de façon interactive | [Navigation](feature-navigation.md) |
| 🔖 Sauter vers des emplacements fréquents | [Signets](feature-bookmarks.md) |
| 📋 Copier et déplacer des fichiers | [Fichiers & Dossiers](feature-files-folders.md) |
| 🎯 Rassembler des fichiers de partout et les transférer | [Zone de transit](feature-target-staging.md) |
| 🔁 Automatiser des commandes répétitives | [Macros](feature-macros.md) |
| ⚙️ Personnaliser nixlper à votre goût | [Configuration](feature-configuration.md) |
| 🔑 Se connecter instantanément à des hôtes SSH | [Connexions SSH](feature-ssh.md) |
| ⚡ Tuer des processus par nom ou port | [Gestion des processus](feature-processes.md) |
| 👤 Changer d'utilisateur sans perdre votre position | [Gestion des utilisateurs](feature-users.md) |
| 🔄 Rester à jour automatiquement | [Mises à jour](feature-updates.md) |
| 💡 Apprendre des astuces au fil de l'utilisation | [Astuces](feature-tips.md) |

---

## Concepts clés

- **Tout est un raccourci.** Toutes les fonctionnalités sont accessibles via des combinaisons `CTRL+X+<touche>` ou des alias courts (ex. `fa`, `ik`, `sn`).
- **Ne retenez rien.** Ouvrez la [Palette de commandes](feature-command-palette.md) (`CTRL+X+A`) et cherchez ce dont vous avez besoin.
- **Nécessite `fzf`** pour la palette, la navigation, le sélecteur SSH et l'éditeur de configuration. Installez-le via votre gestionnaire de paquets (`brew install fzf`, `dnf install fzf`, `apt install fzf`).

---

## Référence rapide

| Raccourci | Action |
|---|---|
| `CTRL+X+A` | Ouvrir la palette de commandes |
| `CTRL+X+N` | Navigateur de fichiers interactif |
| `CTRL+X+B` | Ajouter/supprimer un signet |
| `CTRL+X+D` | Afficher les signets |
| `CTRL+X+C` | Ouvrir l'éditeur de configuration |
| `CTRL+X+S` | Sélecteur de connexion SSH |
| `CTRL+X+W` | Vérifier les mises à jour |
| `CTRL+X+H` | Aide intégrée au shell |
| `CTRL+X+U` | Remonter d'un répertoire |
| `CTRL+P` | Démarrer/arrêter l'enregistrement de macro |

---

## À propos de l'auteur

Bonjour, je suis **Quang Minh** — consultant expert ECM avec une passion pour l'artisanat logiciel et Java.
J'accorde beaucoup d'importance à un code propre et bien conçu, même si je suis encore en chemin pour le maîtriser pleinement.

Nixlper est né d'une obsession simple : **être rapide au terminal**. Si je peux économiser quelques frappes dans un workflow quotidien, je le ferai.

> *"Développer sérieusement sans se prendre au sérieux."*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Quang%20Minh-blue?logo=linkedin)](https://www.linkedin.com/in/quang-minh-t-131048155)

---

[Dépôt GitHub](https://github.com/Minhounet/nixlper) · [Signaler un problème](https://github.com/Minhounet/nixlper/issues) · [Notes de version](https://github.com/Minhounet/nixlper/releases)
