# Zone de transit

> **Rassemblez des fichiers de partout et copiez-les ou archivez-les en une seule opération.**
> Utile pour acheminer des fichiers vers un serveur via `/tmp`, ou regrouper des fichiers éparpillés avant un transfert.

> 🇬🇧 [English version](../feature-target-staging.md)

Le dossier cible vaut par défaut `/tmp/nixlper_target`, et les fichiers qui y arrivent sont passés
en `chmod NIXLPER_TARGET_CHMOD` (défaut `777` — accessible en écriture à tous, pour qu'un autre
utilisateur ou processus de la machine puisse aussi consommer le fichier ; resserrez cette valeur
via `nconf` si ce n'est pas ce que vous voulez).

---

## Commandes

| Commande | Description |
|---|---|
| `tc CHEMIN_FICHIER` | Copier ou déplacer un fichier vers le dossier cible — demande `cp`/`mv` (défaut : `cp`), puis `chmod NIXLPER_TARGET_CHMOD` |
| `tm CHEMIN_FICHIER` | Marquer un fichier pour un archivage groupé ultérieur |
| `tml` | Lister les fichiers actuellement marqués |
| `tum` | Retirer un fichier de la liste de marquage (sélecteur numéroté) |
| `tcm` | Effacer tous les marquages sans copier |
| `tp` / `CTRL+X+Y` | Archiver tous les fichiers marqués dans un `.tgz` horodaté dans le dossier cible, puis effacer les marquages |
| `tsd [CHEMIN_DIR]` | Afficher ou changer le dossier cible pour cette session |
| `tclean` | Supprimer tous les fichiers du dossier cible (confirmation requise) |

Les raccourcis `tcN` et `tmN` sont également disponibles directement depuis la [navigation](feature-navigation.md) et les résultats de `fan`.

---

## Flux de travail typique

```bash
fan rapport          # trouver les fichiers correspondant à "rapport"
tm2                  # marquer le fichier 2
tm5                  # marquer le fichier 5
tml                  # vérifier la liste
tp                   # archiver → /tmp/nixlper_target/nixlper_pack_20260623_143022.tgz
tclean               # nettoyer le dossier cible une fois terminé
```

### Démo

<!-- TODO: ajouter une démo GIF — fan, tm2, tm5, tml, tp, afficher le .tgz résultant -->

---

## Configuration

Changez le dossier cible par défaut via `nconf` (`CTRL+X+C`) → `NIXLPER_TARGET_DIR`, ou définissez-le dans `~/.config/nixlper/nixlper.conf` :

```bash
NIXLPER_TARGET_DIR=/home/partage/transfert
```

Changez les permissions appliquées par `tc` via `NIXLPER_TARGET_CHMOD` (défaut `777`) :

```bash
NIXLPER_TARGET_CHMOD=644
```

Pour changer le dossier uniquement pour la session courante (sans modifier la configuration) :

```bash
tsd /home/partage/transfert
```

---

[← Retour à l'accueil](index.md)
