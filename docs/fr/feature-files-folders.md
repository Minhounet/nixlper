# Fichiers & Dossiers

> **Marquez, ouvrez, sauvegardez, renommez et supprimez des fichiers en toute sécurité — tout au clavier.**

> 🇬🇧 [English version](../feature-files-folders.md)

---

## Marquer un dossier pour y revenir rapidement

```bash
c       # marquer le dossier courant
gc      # revenir au dossier marqué depuis n'importe où
```

### Démo

<!-- TODO: ajouter une démo GIF — naviguer profondément dans une arborescence, taper c, aller ailleurs, taper gc pour revenir -->

---

## Marquer un fichier pour l'ouvrir rapidement

```bash
cf CHEMIN_FICHIER    # marquer un fichier
gcf                  # ouvrir le fichier marqué dans $NIXLPER_EDITOR depuis n'importe où
```

---

## Presse-papier

```bash
cpcb [CHEMIN_FICHIER]    # copier le chemin complet d'un fichier dans le presse-papier (défaut : répertoire courant)
cpdcb CHEMIN_FICHIER     # copier le chemin complet du répertoire contenant le fichier
```

Nécessite `xclip`, `xsel` ou `pbcopy`.

### Démo

<!-- TODO: ajouter une démo GIF — cpcb sur un fichier, coller dans une autre commande -->

---

## Instantané & restauration

```bash
sn CHEMIN_FICHIER          # sauvegarder un fichier dans la zone d'instantanés
re [CHEMIN_FICHIER]        # restaurer un fichier — omettre CHEMIN_FICHIER pour un sélecteur interactif
```

Les instantanés sont stockés dans `NIXLPER_SNAPSHOT_DIR`. Le fichier original n'est jamais supprimé — `sn` est une copie de sécurité, pas un déplacement.

### Démo

<!-- TODO: ajouter une démo GIF — sn sur un fichier de configuration, le modifier, re pour le restaurer de façon interactive -->

---

## Rechercher & remplacer dans un fichier

```bash
rp NOM_FICHIER
```

Recherche et remplacement interactifs avec la **syntaxe `:s` de vi** — fini les one-liners `sed` cryptiques. `rp` pose quatre questions, puis construit et exécute l'équivalent de `:%s/RECHERCHE/REMPLACEMENT/FLAGS` (via `ex`, fourni avec vim) :

```text
$ rp app.conf
Search  (vi regex): ^timeout=\(.*\)
Replace (\1 and & work as in vi): retry=\1
Lines   (Enter = all, or 10,20 or /start/,/end/):
Flags   (g = every match per line, i = ignore case, c = confirm each; default g):
   1 - timeout=30
   1 + retry=30
1 line(s) would change in app.conf
Apply? (y/n, default is n): y
```

- **Aperçu d'abord** — seules les lignes modifiées sont affichées, rien n'est écrit tant que vous ne répondez pas `y`.
- **Délimiteur géré pour vous** — des chemins comme `/usr/bin` n'ont pas besoin d'être échappés avec `\/`.
- **Flags** — `g` (défaut) toutes les occurrences d'une ligne, `i` ignorer la casse, `c` confirmer chaque occurrence une par une, comme dans vi (nécessite `vim`).
- **Plage de lignes** — laisser vide pour tout le fichier, ou `10,20`, `5`, `/début/,/fin/`.
- **Annuler** — le fichier est sauvegardé (instantané) avant modification : `re NOM_FICHIER` le restaure. Si un instantané existe déjà, une confirmation est demandée avant de l'écraser. Désactivable avec `NIXLPER_REPLACE_SNAPSHOT=false`.
- **Pipes** — un `|` nu est refusé (ex le traiterait comme séparateur de commandes) : utilisez `[|]` dans la recherche, `\|` dans le remplacement.
- Les fichiers binaires et en lecture seule sont refusés. Nécessite `ex` (fourni avec vim).

---

## Renommage par motif

```bash
rn NOM_FICHIER MOTIF [REMPLACEMENT]
```

Supprimez ou remplacez un motif dans un nom de fichier sans taper la commande `mv` complète.

```bash
rn fichier_peppa.txt _peppa              # → fichier.txt       (supprimer le motif)
rn test-ancien.txt -ancien -nouveau      # → test-nouveau.txt  (remplacer le motif)
```

---

## Ouvrir le fichier le plus récent

```bash
olf
```

Ouvre le fichier le plus récemment modifié dans l'arborescence du répertoire courant avec `$NIXLPER_EDITOR`. Utile après une compilation ou une génération de logs.

---

## Suppression sécurisée

Ces commandes affichent une commande `rm -i` pré-remplie pour vous laisser vérifier et confirmer — elles ne sont jamais exécutées automatiquement.

| Raccourci | Commande générée |
|---|---|
| `CTRL+X+E` | `rm -i -rf /dossier/courant && cd ..` — supprimer le dossier courant |
| `CTRL+X+R` | `rm -i -rf /dossier/courant/*` — supprimer le contenu du dossier courant |

Les commandes apparaissent sur votre ligne de commande. Vous appuyez sur Entrée pour les exécuter, vous laissant une dernière chance d'annuler.

> Cela permet d'utiliser `rm -rf` rapidement sans qu'il reste dans l'historique du shell.

---

## Ajouter le chemin courant à `$PATH`

```bash
ap
```

Ajoute le répertoire courant en tête de `PATH` dans `~/.bashrc` et le recharge immédiatement. Utile quand vous développez un script et souhaitez l'exécuter sans `./`.

---

[← Retour à l'accueil](index.md)
