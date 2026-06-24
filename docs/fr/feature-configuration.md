# Configuration

> **Personnalisez chaque aspect de Nixlper de façon interactive — sans édition manuelle de fichiers.**

> 🇬🇧 [English version](../feature-configuration.md)

| Raccourci | Alias |
|---|---|
| `CTRL+X+C` | `nconf` |

Nécessite [`fzf`](https://github.com/junegunn/fzf#installation).

---

## Démo

<!-- TODO: ajouter une démo GIF — CTRL+X+C, parcourir les paramètres, modifier NIXLPER_EDITOR, sauvegarder -->

---

## Fonctionnement

`nconf` ouvre une liste de recherche floue de tous les paramètres configurables. Sélectionnez une entrée et appuyez sur Entrée :

- **Paramètres booléens / énumération** — présentés sous forme de liste de sélection.
- **Paramètres texte / entier** — présentés sous forme de prompt pré-rempli.

Seules les valeurs différentes de la valeur par défaut sont écrites dans `~/.config/nixlper/nixlper.conf`. Le fichier reste minimal et lisible.

Les modifications prennent effet dans les nouveaux shells. Pour les appliquer immédiatement : `source ~/.bashrc`.

---

## Paramètres courants

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_EDITOR` | `vim` | Éditeur pour les commandes d'ouverture de fichiers |
| `NIXLPER_NAVIGATE_MODE` | `tree` | Mode de navigation (`tree` ou `flat`) |
| `NIXLPER_DISABLE_WELCOME_MESSAGE` | `false` | Masquer la bannière de démarrage |
| `NIXLPER_DISABLE_TIPS` | `false` | Masquer l'astuce de démarrage |
| `NIXLPER_UPDATE_CHECK` | `true` | Vérifier automatiquement les mises à jour à la connexion |
| `NIXLPER_UPDATE_AUTO` | `false` | Installer automatiquement les mises à jour détectées |
| `NIXLPER_UPDATE_CHANNEL` | `stable` | Canal de mise à jour (`stable` / `edge` / `off`) |
| `NIXLPER_TARGET_DIR` | `/tmp/nixlper_target` | Dossier de transit pour copier/marquer/archiver |

## Paramètres avancés

| Variable | Description |
|---|---|
| `NIXLPER_UPDATE_CHECK_INTERVAL` | Secondes entre les vérifications automatiques (défaut `86400`) |
| `NIXLPER_UPDATE_TIMEOUT` | Délai d'expiration de la sonde réseau en secondes (défaut `2`) |
| `NIXLPER_BOOKMARKS_FILE` | Chemin du fichier de signets |
| `NIXLPER_SNAPSHOT_DIR` | Chemin du répertoire d'instantanés |
| `NIXLPER_CUSTOM_DIR` | Chemin du répertoire de scripts personnalisés |
| `NIXLPER_SSH_CONNECTIONS_FILE` | Chemin du fichier de connexions SSH |
| `NIXLPER_SSH_IDENTITY_FILE` | Clé SSH d'identité par défaut |

---

## Emplacement du fichier de configuration

Les paramètres sont stockés dans `~/.config/nixlper/nixlper.conf` (utilisateur) et `/etc/nixlper/nixlper.conf` (système, installations RPM/DEB).

Les paramètres utilisateur ont toujours priorité sur les paramètres système.

---

## Migration depuis `~/.bashrc`

Si vos variables Nixlper se trouvent encore dans `~/.bashrc` (ancienne installation manuelle), `nconf` proposera une migration unique :
- Déplace tous les exports `NIXLPER_*` vers `~/.config/nixlper/nixlper.conf`
- Laisse `~/.bashrc` avec uniquement la ligne `source`
- Crée une sauvegarde avant toute modification

En cas d'échec de la migration, des instructions de récupération sont affichées, y compris comment restaurer la sauvegarde.

---

## Scripts personnalisés

Tout script placé dans `NIXLPER_CUSTOM_DIR` (défaut : `$NIXLPER_INSTALL_DIR/custom`) est automatiquement sourcé à la connexion, vous permettant d'étendre Nixlper avec vos propres alias et fonctions.

---

[← Retour à l'accueil](index.md)
