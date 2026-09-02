# Signets

> **Enregistrez vos répertoires les plus visités et revenez-y instantanément.**

> 🇬🇧 [English version](../feature-bookmarks.md)

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+B` | — | Ajouter ou supprimer un signet pour le dossier courant |
| `CTRL+X+D` | `bd` | Afficher les signets enregistrés et y accéder |

---

## Démo

<!-- TODO: ajouter une démo GIF — naviguer vers un dossier, CTRL+X+B pour l'ajouter aux signets, CTRL+X+D pour lister, sélectionner un pour y accéder -->

---

## Utilisation

### Ajouter un signet

Naviguez vers n'importe quel dossier, puis appuyez sur `CTRL+X+B`. Il vous sera demandé de saisir un nom pour le signet.

```
$ cd /var/log/nginx
$ # appuyer sur CTRL+X+B
Nom du signet : nginx-logs
✔ Signet "nginx-logs" ajouté.
```

### Supprimer un signet

Appuyez à nouveau sur `CTRL+X+B` depuis n'importe quel répertoire. Si le dossier courant est déjà dans les signets, vous aurez la possibilité de le supprimer.

### Accéder à un signet

Appuyez sur `CTRL+X+D` (ou lancez `bd`) pour afficher les signets enregistrés et y accéder.

Si [`fzf`](https://github.com/junegunn/fzf#installation) est installé, cela ouvre un **filtre incrémental** qui combine les deux approches — chaque entrée est affichée avec son numéro d'index, donc :
- taper des **chiffres** (ex. `3`) saute directement à l'entrée numérotée correspondante ;
- taper des **lettres** (ex. `nginx`) filtre la liste en direct par nom de signet ou par chemin.

Utilisez les flèches pour naviguer, `Entrée` pour y accéder, `Échap` pour annuler. Sans `fzf` — ou avec le mode flou désactivé — revient au sélecteur numéroté classique : saisissez un numéro et appuyez sur Entrée pour y accéder.

Les signets dont le répertoire a été supprimé depuis leur enregistrement sont ignorés automatiquement.

Vous pouvez aussi taper directement le nom du signet à n'importe quel prompt — chaque signet étant un véritable alias bash, taper `nginx-logs` y accède exactement comme n'importe quelle autre commande. Le sélecteur ci-dessus est une deuxième façon de le retrouver quand vous ne vous souvenez plus du nom exact.

---

## Stockage

Les signets sont stockés dans `NIXLPER_BOOKMARKS_FILE` (par défaut : `$NIXLPER_INSTALL_DIR/.nixlper_bookmarks` pour une installation manuelle, `~/.local/share/nixlper/bookmarks` pour RPM/DEB).

### Configuration

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_BOOKMARKS_FILE` | `~/.local/share/nixlper/bookmarks` | Chemin du fichier de signets |
| `NIXLPER_BOOKMARKS_FUZZY` | `true` | Utiliser le filtre flou `fzf` quand `fzf` est installé ; `false` force toujours le sélecteur numéroté |

Configurez via `nconf` (`CTRL+X+C`) ou `~/.config/nixlper/nixlper.conf`.

---

[← Retour à l'accueil](index.md)
