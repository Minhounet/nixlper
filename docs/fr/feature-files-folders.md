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
