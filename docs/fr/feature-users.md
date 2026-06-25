# Gestion des utilisateurs

> **Changez d'utilisateur sans perdre votre répertoire courant.**

> 🇬🇧 [English version](../feature-users.md)

| Alias | Description |
|---|---|
| `sucd UTILISATEUR` | `su - UTILISATEUR` et `cd` immédiatement vers le dossier courant |

---

## Démo

<!-- TODO: ajouter une démo GIF — dans /var/log/app, taper sucd deploy, atterrir dans le même dossier en tant qu'utilisateur deploy -->

---

## Utilisation

```bash
sucd deploy
```

Équivalent à `su - deploy` suivi de `cd /votre/chemin/courant`. Utile quand vous devez exécuter des commandes en tant qu'autre utilisateur au même emplacement.

---

## Remarques

- Nécessite les permissions `su` pour l'utilisateur cible.
- Le répertoire courant doit être accessible par l'utilisateur cible pour que le `cd` réussisse.

---

[← Retour à l'accueil](index.md)
