# Navigation

> **Parcourez votre système de fichiers de façon interactive — ouvrez des fichiers, entrez dans des dossiers, cherchez par nom ou par contenu, sans quitter le terminal.**

> 🇬🇧 [English version](../feature-navigation.md)

Nécessite [`fzf`](https://github.com/junegunn/fzf#installation). Le mode arborescence nécessite également `tree`.

---

## Navigateur interactif

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+N` | — | Ouvrir le navigateur de fichiers interactif |
| `CTRL+X+U` | — | Remonter d'un répertoire (`cd ..`) |
| `CTRL+X+J` | `rd` | Naviguer vers un répertoire récemment visité |

### Démo

<!-- TODO: ajouter une démo GIF — CTRL+X+N, naviguer dans l'arborescence, ouvrir un fichier avec vN, aller dans un dossier avec cdfN -->

### Fonctionnement

`CTRL+X+N` affiche le contenu du répertoire courant avec des raccourcis numérotés pour chaque élément :

| Raccourci | Action |
|---|---|
| `vN` | Ouvrir le fichier N dans `$NIXLPER_EDITOR` |
| `nN` ou `CTRL+X+N` | Entrer dans le dossier N |
| `cdfN` | `cd` vers le dossier contenant l'élément N |
| `dN` | Supprimer l'élément N (avec confirmation) |
| `tcN` | Copier l'élément N vers le [dossier de transit](feature-target-staging.md) |
| `tmN` | Marquer l'élément N pour un archivage groupé |

Deux modes d'affichage sont disponibles :

- **tree** (défaut) — utilise la commande `tree` pour une hiérarchie visuelle
- **flat** — liste simple, sans dépendance externe

Changez de mode via `nconf` (`CTRL+X+C`) → `NIXLPER_NAVIGATE_MODE`, ou basculez l'affichage taille/permissions avec :

```bash
toggle_navigation_mode
```

---

## Aller dans le dossier d'un fichier

```bash
cdf CHEMIN_FICHIER
```

Navigue directement vers le répertoire contenant `CHEMIN_FICHIER`. Utile quand vous connaissez le chemin d'un fichier mais voulez atterrir dans son dossier.

---

## Rechercher par nom

```bash
fan MOTIF
```

Lance `find . -iname "*MOTIF*"` et affiche les résultats avec les mêmes raccourcis numérotés que le navigateur (`vN`, `cdfN`, `dN`, `tcN`, `tmN`).

### Démo

<!-- TODO: ajouter une démo GIF — fan rapport, les résultats apparaissent, ouvrir l'un avec vN, supprimer un autre avec dN -->

---

## Rechercher par contenu

```bash
fag MOTIF
```

Lance `grep -rn MOTIF .` et affiche chaque correspondance avec un raccourci `vN` qui ouvre le fichier **directement à la ligne correspondante** dans votre éditeur.

### Démo

<!-- TODO: ajouter une démo GIF — fag TODO, les résultats apparaissent, appuyer sur v1 pour sauter à la ligne correspondante -->

---

## Répertoires récents

```bash
rd
```

Ou appuyez sur `CTRL+X+J`. Affiche une liste numérotée des répertoires les plus récemment visités (le plus récent en premier). Saisissez un numéro et appuyez sur Entrée pour y accéder. Le répertoire personnel (`~`) et la racine (`/`) sont exclus — trop génériques pour être utiles dans cette liste.

Les répertoires supprimés depuis la dernière visite sont ignorés automatiquement.

### Configuration

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_RECENT_DIRS_MAX` | `20` | Nombre maximum d'entrées à mémoriser |
| `NIXLPER_RECENT_DIRS_FILE` | `~/.local/share/nixlper/recent_dirs` | Chemin du fichier d'historique |

Configurez via `nconf` (`CTRL+X+C`) ou `~/.config/nixlper/nixlper.conf`.

---

[← Retour à l'accueil](index.md)
