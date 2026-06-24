# Connexions SSH

> **Connectez-vous à des hôtes SSH enregistrés en quelques secondes — mot de passe une fois, sans mot de passe ensuite.**

> ⚠️ **Expérimental** — pas encore testé en environnement réel. Merci de [signaler les problèmes](https://github.com/Minhounet/nixlper/issues).

> 🇬🇧 [English version](../feature-ssh.md)

Nécessite [`fzf`](https://github.com/junegunn/fzf#installation).

---

## Commandes

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+S` | `sc` | Ouvrir le sélecteur SSH — choisir un hôte et se connecter |
| — | `sca` | Ajouter une nouvelle connexion SSH |
| — | `scr` | Supprimer une connexion enregistrée (sélecteur fzf) |
| — | `scl` | Lister toutes les connexions enregistrées |

---

## Démo

<!-- TODO: ajouter une démo GIF — scl pour afficher les connexions, CTRL+X+S pour en sélectionner une et se connecter -->

---

## Première utilisation

Lors de la première connexion à un nouvel hôte, nixlper :
1. Génère `~/.ssh/nixlper_id_rsa` s'il n'existe pas.
2. Utilise `ssh-copy-id` pour envoyer la clé vers l'hôte distant.
3. Demande votre mot de passe **une seule fois**.

Toutes les connexions suivantes utilisent la clé — aucun mot de passe nécessaire.

---

## Ajouter une connexion

```bash
sca
```

Il vous sera demandé de renseigner :
- **Libellé** — un nom court pour la connexion (ex. `serveur-prod`)
- **Utilisateur** — le nom d'utilisateur SSH
- **Hôte** — nom d'hôte ou adresse IP
- **Port** — défaut `22`
- **Fichier d'identité** — laisser vide pour utiliser le défaut global (`NIXLPER_SSH_IDENTITY_FILE`)

---

## Format du fichier de connexions

Les connexions sont stockées dans `~/.config/nixlper/ssh_connections`, une par ligne :

```
libellé|utilisateur|hôte|port|fichier_identité
# exemple — laisser fichier_identité vide pour le défaut global
monserveur|alice|192.168.1.10|22|
prod|deploy|10.0.0.5|2222|~/.ssh/cle_prod
```

---

## Configuration

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_SSH_CONNECTIONS_FILE` | `~/.config/nixlper/ssh_connections` | Chemin du fichier de connexions |
| `NIXLPER_SSH_IDENTITY_FILE` | `~/.ssh/nixlper_id_rsa` | Clé SSH par défaut |

Configurable via `nconf` (`CTRL+X+C`).

---

[← Retour à l'accueil](index.md)
