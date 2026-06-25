# Signets

> **Enregistrez vos répertoires les plus visités et revenez-y instantanément.**

> 🇬🇧 [English version](../feature-bookmarks.md)

| Raccourci | Description |
|---|---|
| `CTRL+X+B` | Ajouter ou supprimer un signet pour le dossier courant |
| `CTRL+X+D` | Afficher tous les signets enregistrés |

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

Appuyez sur `CTRL+X+D` pour afficher tous les signets enregistrés. Sélectionnez-en un et appuyez sur Entrée — nixlper effectue un `cd` directement vers ce dossier.

---

## Stockage

Les signets sont stockés dans `NIXLPER_BOOKMARKS_FILE` (par défaut : `$NIXLPER_INSTALL_DIR/.nixlper_bookmarks` pour une installation manuelle, `~/.local/share/nixlper/bookmarks` pour RPM/DEB).

Configurez le chemin via `nconf` (`CTRL+X+C`).

---

[← Retour à l'accueil](index.md)
