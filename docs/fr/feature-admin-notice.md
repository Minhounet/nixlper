# Notice Admin

> **Laissez un message pour la prochaine personne qui se connecte — root ou n'importe quel compte.**

> 🇬🇧 [English version](../feature-admin-notice.md)

| Alias | Description |
|---|---|
| `bset` | Enregistrer une notice affichée à tout le monde à la prochaine connexion |
| `bshow` | Afficher la notice actuelle à la demande |
| `bclear` | Supprimer la notice actuelle |

---

## Utilisation

```bash
bset
```

`bset` est interactif : il demande le texte du message, puis une expiration optionnelle en jours.

- Laissez l'expiration vide pour une notice **persistante** — affichée à chaque connexion
  jusqu'à ce que vous lanciez `bclear`. Utilisez ceci pour tout ce qui doit rester visible tant
  que ce n'est pas réellement résolu, comme un contournement temporaire.
- Entrez un nombre de jours pour une notice qui **disparaît d'elle-même** après ce délai.
  L'expiration est vérifiée à la connexion, donc une notice expirée peut rester visible
  inoffensivement jusqu'à la prochaine connexion — elle n'est pas supprimée par une tâche
  planifiée en arrière-plan.

Ceci est indépendant du message de bienvenue et des astuces de nixlper — c'est destiné aux
notices entre opérateurs à propos de la machine elle-même (redémarrage prévu, contournement
temporaire, changement dont on doit être informé).

---

## Exemple

```bash
$ bset
Message to broadcast at next login: Contournement DNS temporaire en place, voir ticket #123
Expire in how many days? (blank = persistent until bclear): 7
2026-08-21 09:12:03 INFO Notice set, expires in 7 day(s).
```

À la prochaine connexion (n'importe quel utilisateur) :

```
⚠️  ──────────────────────────── ADMIN NOTICE ────────────────────────────
Contournement DNS temporaire en place, voir ticket #123
────────────────────────────────────────────────────────────────────────
```

---

## Supprimer une notice

```bash
bclear
```

Supprime la notice immédiatement, quelle que soit l'expiration définie.

---

## Configuration

Disponible via `nconf` (`CTRL+X+C`) :

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_DISABLE_BROADCAST_MESSAGE` | `false` | Supprimer la notice admin à la connexion |
| `NIXLPER_BROADCAST_MESSAGE_FILE` | voir ci-dessous | Emplacement de stockage de la notice |

| Type d'installation | Chemin par défaut |
|---|---|
| Installation manuelle | `$NIXLPER_INSTALL_DIR/broadcast_message` |
| RPM / DEB | `/etc/nixlper/broadcast_message` |

Seul celui qui peut écrire à ce chemin (typiquement root sur une installation système) peut
enregistrer ou supprimer une notice — tous les utilisateurs peuvent la lire.

---

[← Retour à l'accueil](index.md)
