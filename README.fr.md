# NIXLPER

> 🚀 **Version actuelle : v2.0.0** — [Notes de version](https://github.com/Minhounet/nixlper/releases)
>
> Nixlper évolue en permanence. Les versions taguées sont des instantanés stables, mais la branche `master` contient toujours les dernières améliorations. Le script `install.sh` installe depuis la dernière version publiée — pour obtenir l'absolute dernier état, compilez depuis les sources avec `./build.sh`.

> 🇬🇧 [English version](README.md)

Ceci est mon assistant personnel en environnement Unix. Je me suis inspiré de la philosophie de [Total Commander](https://www.ghisler.com/accueil.htm) et j'ai essayé de l'appliquer sous Unix.

> ⚠️ **L'aide intégrée (`CTRL+X puis H`) est uniquement disponible en anglais pour l'instant. Une traduction française est prévue dans une prochaine version.**

## 🎉 v2.0.0 — Un nouveau départ

La version 2.0.0 marque un tournant dans le projet. Ce qui a commencé comme une collection personnelle de raccourcis bash est devenu un outil structuré, correctement packagé, avec une vraie histoire de distribution.

L'ajout phare est la **palette de commandes** (`CTRL+X+A`) : un popup de recherche floue listant toutes les commandes disponibles (avec leur description, catégorie, raccourci clavier et alias). Plus besoin de se souvenir de quoi que ce soit — ouvrez la palette et tapez. Cette fonctionnalité change la façon dont l'outil est utilisé et découvert, et c'est la principale raison pour laquelle cette version mérite un changement de version majeure.

Au-delà de ça, v2.0.0 apporte :
- 📦 **Paquets RPM et DEB** — installez via votre gestionnaire de paquets système, sans étape manuelle
- ⚡ **`install.sh`** — un script d'installation et de mise à jour en une seule ligne curl
- 🔍 **`fag`** — recherche dans les fichiers et ouverture directe à la ligne correspondante dans votre éditeur
- 🗂️ **Raccourcis `fan`** — supprimez ou faites un `cd` vers n'importe quel résultat de recherche directement
- ✏️ **Renommage par motif** (`rn`) et une commande **rafraîchissement** (`rf`)
- 💡 Un **système de conseils** qui affiche un nouveau conseil à chaque démarrage du shell
- 🛠️ Détection des outils manquants au démarrage pour savoir exactement quoi installer

## Description

L'objectif de ce projet bash est de fournir des commandes Unix utiles à diverses fins. Il s'inspire de la philosophie de [Total Commander](https://www.ghisler.com/accueil.htm),
c'est pourquoi il contient beaucoup de raccourcis clavier.
Vous pouvez le compiler vous-même en suivant le [chapitre suivant](#prérequis-pour-la-compilation-sh) ou simplement télécharger la dernière version depuis GitHub.

## Architecture

Ce projet est composé de plusieurs scripts `.sh` modulaires situés dans `src/main`.
Le processus de compilation (via `build.sh`) les concatène et les empaquète dans
une archive distribuable unique. Après extraction, le script principal
`nixlper.sh` orchestre les modules internes.

Cette approche permet :
- Un développement et une maintenance plus faciles des modules individuels.
- Un script installable unique pour les utilisateurs finaux.

Le résultat de la compilation se trouve dans `build/distributions/`.

## Prérequis pour la compilation sh

Vous avez besoin d'une ligne de commande bash. J'utilise personnellement [Git bash](https://git-scm.com/downloads).

## Compilation avec sh

La commande sh est simple et directe.
```bash
# Exécutez la commande
./build.sh
```
Vous obtiendrez dans `build/distributions` l'archive `nixlper-<version>.tar`.

## Installation

> **Aperçu des périmètres**
> - **Installation rapide / Installation manuelle** — utilisateur courant uniquement : configure `~/.bashrc`.
> - **Installation rapide `--system` / Manuelle `install-system`** — tous les utilisateurs : écrit `/etc/profile.d/nixlper.sh` (nécessite `sudo`).
> - **RPM / DEB** — tous les utilisateurs : même mécanisme, géré par le gestionnaire de paquets.

### Installation rapide (recommandée)

La façon la plus simple d'installer ou de mettre à jour Nixlper est d'utiliser le script d'installation.
Il détecte automatiquement si Nixlper est déjà installé et effectue une première installation ou une mise à jour en conséquence.
Cette méthode active nixlper **pour l'utilisateur courant uniquement** en ajoutant un bloc dans `~/.bashrc`.

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh | bash
```

Ou téléchargez-le et exécutez-le manuellement :

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh
chmod +x install.sh
./install.sh
```

Le script va :
- Récupérer la dernière version depuis GitHub
- Détecter si Nixlper est déjà installé
- **Première installation** : demander un répertoire d'installation (par défaut `/opt/nixlper`), télécharger, extraire et configurer `.bashrc`
- **Mise à jour** : télécharger la nouvelle version dans le répertoire d'installation existant, en préservant vos scripts personnalisés

### Installation rapide — système (tous les utilisateurs)

Pour installer pour tous les utilisateurs, passez `--system`. Cela nécessite d'être root et écrit
`/etc/profile.d/nixlper.sh` et `/etc/nixlper/nixlper.conf` au lieu de modifier `~/.bashrc`.

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh)" -- --system
```

Ou téléchargez et exécutez manuellement :

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/Minhounet/nixlper/master/install.sh
chmod +x install.sh
sudo ./install.sh --system
```

### Installation manuelle

Cette méthode active également nixlper **pour l'utilisateur courant uniquement** en ajoutant un bloc dans `~/.bashrc`.

Effectuez les commandes ci-dessous pour la première installation :
- Placez l'archive sur n'importe quel serveur dans le dossier où vous souhaitez l'installer (par exemple **/opt/nixlper**)
- Décompressez-la avec la commande `tar -xf`
- Puis exécutez `./nixlper.sh install`

```bash
mkdir -p /opt/nixlper
# copiez l'archive, /tmp est un exemple
cp /tmp/nixlper*tar /opt/nixlper
cd /opt/nixlper
tar -xf nixlper*.tar
./nixlper.sh install
```

Votre fichier `.bashrc` sera mis à jour et nixlper sera prêt à être utilisé à la prochaine connexion.

### Mise à jour manuelle

Pour une mise à jour, suivez les mêmes étapes sauf pour la dernière commande qui sera :
`./nixlper.sh update`

### Désinstallation manuelle

Exécutez la commande ci-dessous depuis le répertoire d'installation :

```bash
cd /opt/nixlper
./nixlper.sh uninstall
```

Pour une installation système :

```bash
sudo /opt/nixlper/nixlper.sh uninstall-system
```

### Installation RPM (RHEL / Fedora / Rocky Linux)

Téléchargez le dernier `.rpm` depuis la page [GitHub Releases](https://github.com/Minhounet/nixlper/releases), puis installez-le :

```bash
# Avec dnf (recommandé — gère les dépendances)
sudo dnf install nixlper-*.rpm

# Ou avec rpm directement
sudo rpm -ivh nixlper-*.rpm
```

Pour mettre à niveau une installation existante :

```bash
sudo dnf upgrade nixlper-*.rpm
# ou
sudo rpm -Uvh nixlper-*.rpm
```

Après installation, nixlper est automatiquement activé pour tous les utilisateurs via `/etc/profile.d/nixlper.sh` à la prochaine connexion.
Les paramètres par défaut du système sont dans `/etc/nixlper/nixlper.conf` (préservés lors des mises à niveau).
Les paramètres utilisateur vont dans `~/.config/nixlper/nixlper.conf`.

Pour supprimer :

```bash
sudo dnf remove nixlper
# ou
sudo rpm -e nixlper
```

### Installation DEB (Debian / Ubuntu)

Téléchargez le dernier `.deb` depuis la page [GitHub Releases](https://github.com/Minhounet/nixlper/releases), puis installez-le :

```bash
# Avec apt (recommandé — gère les dépendances)
sudo apt install ./nixlper_*_all.deb

# Ou avec dpkg directement
sudo dpkg -i nixlper_*_all.deb
```

Pour mettre à niveau, relancez simplement la commande d'installation avec le nouveau fichier `.deb`.

Après installation, nixlper est automatiquement activé pour tous les utilisateurs via `/etc/profile.d/nixlper.sh` à la prochaine connexion.
Les paramètres par défaut du système sont dans `/etc/nixlper/nixlper.conf` (préservés lors des mises à niveau).
Les paramètres utilisateur vont dans `~/.config/nixlper/nixlper.conf`.

Pour supprimer :

```bash
sudo apt remove nixlper
# ou
sudo dpkg -r nixlper
```

## Fonctionnalités

> Dans cette section, `$NIXLPER_EDITOR` désigne l'éditeur utilisé pour ouvrir les fichiers
> (par défaut `vim`, configurable via la variable d'environnement `NIXLPER_EDITOR`).

### Palette de commandes (Trouver une action)

Le moyen le plus rapide de découvrir et d'exécuter n'importe quelle commande Nixlper. Elle ouvre un popup de recherche floue propulsé par `fzf` listant toutes les commandes disponibles (avec leur description, catégorie, raccourci clavier et alias).

- `CTRL + X puis A` (ou `fa`) : ouvrir la palette de commandes et rechercher par nom, description ou catégorie

> Nécessite [`fzf`](https://github.com/junegunn/fzf#installation).

### Favoris (Bookmarks)

- `CTRL + X puis D` : afficher les favoris existants
- `CTRL + X puis B` : ajouter ou supprimer un favori pour le dossier **courant**

### Fichiers et dossiers

- `cdf CHEMIN` : aller dans le dossier contenant le fichier

- `c` : marquer le dossier courant, utiliser `gc` pour y revenir depuis n'importe où
- `cf CHEMIN` : marquer un fichier comme courant, utiliser `gcf` pour l'ouvrir dans `$NIXLPER_EDITOR` depuis n'importe où

- `cpcb [CHEMIN]` : copier le chemin complet d'un fichier dans le presse-papiers (répertoire courant par défaut si aucun argument)
- `cpdcb CHEMIN` : copier le chemin complet du dossier contenant le fichier dans le presse-papiers

  (Le presse-papiers nécessite `xclip`, `xsel` ou `pbcopy`.)

- `sn CHEMIN` : sauvegarder un instantané d'un fichier pour pouvoir le restaurer plus tard
- `re [CHEMIN]` : restaurer un fichier précédemment sauvegardé. Sans argument, une liste interactive des fichiers restaurables est affichée
- `olf` : ouvrir le fichier le plus récemment modifié dans l'arborescence du répertoire courant avec `$NIXLPER_EDITOR`
- `rn FICHIER MOTIF [REMPLACEMENT]` : renommer un fichier en supprimant ou remplaçant un motif
  (ex. `rn file_peppa.txt _peppa` → `file.txt`, `rn test-old.txt -old -new` → `test-new.txt`)

- `CTRL + X puis E` : afficher une commande rm sécurisée du type `rm -i -rf /tmp/dossier && cd..` pour supprimer rapidement le dossier courant sans polluer votre historique bash avec `rm -rf *`
- `CTRL + X puis R` : afficher une commande rm sécurisée du type `rm -i -rf /tmp/dossier/*` pour supprimer rapidement le contenu du dossier courant

### Processus

- `ik` : kill interactif — tuer par motif ou par port (le mode port nécessite `netstat`)

### Utilisateurs

- `sucd UTILISATEUR` : effectuer un `su - UTILISATEUR` en restant dans le dossier courant

### Navigation

- `CTRL + X puis U` : effectuer un `cd ..`
- `CTRL + X puis N` : afficher une navigation interactive dans les sous-dossiers et fichiers avec alias et copier-coller
  (La navigation peut utiliser le mode arbre ou plat. "tree" est la valeur par défaut et nécessite `tree`)

Voir ```export NIXLPER_NAVIGATE_MODE=tree``` dans `~/.bashrc`.

- `toggle_navigation_mode` :
  - basculer l'affichage de la taille des éléments pendant la navigation (très utile quand votre disque dur est plein !)
  - affiche également les permissions des fichiers quand l'option est activée

- `fan MOTIF` : exécute `find . -iname "*MOTIF*"` et affiche les résultats comme la commande `CTRL + X puis N`.
  Chaque résultat propose des raccourcis pour ouvrir le fichier (`vN`), faire un cd dans son dossier (`cdfN`), ou le supprimer (`dN`)
- `fag MOTIF` : exécute `grep -rn MOTIF .` et affiche chaque correspondance avec un raccourci (`vN`) pour ouvrir le fichier directement à la ligne correspondante

### Macros

Enregistrez une séquence de commandes une fois et rejouez-la avec un seul raccourci.

- `CTRL + P` (ou `sr`) : démarrer l'enregistrement
- `CTRL + P, CTRL + P` (ou `fr`) : arrêter l'enregistrement (lie les commandes enregistrées à `CTRL + X, CTRL + X`)
- `CTRL + X, CTRL + X` : rejouer les commandes enregistrées
- `CTRL + P, CTRL + L` : re-lier et rejouer la dernière macro enregistrée (persistée entre les sessions)

### Utilitaires

- `CTRL + X puis O` : ouvrir `nixlper.sh` dans `$NIXLPER_EDITOR` pour des modifications rapides
- `rf` : rafraîchir le répertoire courant (efface l'écran et liste son contenu ; retourne au home si le dossier a été supprimé)
- `ap` : ajouter le chemin courant en tête de la variable `PATH` dans `~/.bashrc` (si pas déjà présent)

### Scripts personnalisés

Tout script placé dans le répertoire custom (par défaut `${NIXLPER_INSTALL_DIR}/custom`, configurable via
`NIXLPER_CUSTOM_DIR`) est automatiquement sourcé à la connexion, vous pouvez ainsi étendre Nixlper avec vos propres
alias et fonctions.

### Aide intégrée

- `CTRL + X puis H` : rechercher de l'aide par sujet (utilise `fzf` et `less`)

> ⚠️ L'aide intégrée est uniquement disponible en anglais pour l'instant. Une traduction française est prévue dans une prochaine version.

### Version et logo

- `CTRL + X puis V` : afficher le logo Nixlper avec les informations de version et le SHA git

### Conseils (Tips)

Un conseil est affiché automatiquement à chaque démarrage du shell (en parcourant tous les conseils dans l'ordre).

- `CTRL + X puis T` (ou `tip`) : afficher un conseil aléatoire à tout moment

Définissez `NIXLPER_DISABLE_TIPS=true` dans votre configuration pour désactiver le conseil au démarrage (la commande `tip` fonctionne toujours).

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour les détails.
