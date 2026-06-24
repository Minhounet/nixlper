# Macros

> **Enregistrez une séquence de commandes une fois et rejouez-la avec un seul raccourci.**
> Aucun script nécessaire — enregistrez simplement ce que vous tapez.

> 🇬🇧 [English version](../feature-macros.md)

---

## Raccourcis

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+P` | `sr` | Démarrer l'enregistrement |
| `CTRL+P, CTRL+P` | `fr` | Arrêter l'enregistrement (lie les commandes enregistrées à `CTRL+X+CTRL+X`) |
| `CTRL+X+CTRL+X` | — | Rejouer la macro enregistrée |
| `CTRL+P+CTRL+L` | — | Recharger et rejouer la dernière macro enregistrée (survit aux redémarrages de session) |

---

## Démo

<!-- TODO: ajouter une démo GIF — CTRL+P pour démarrer, taper quelques commandes, CTRL+P CTRL+P pour arrêter, CTRL+X+CTRL+X pour rejouer -->

---

## Fonctionnement

1. Appuyez sur `CTRL+P` pour démarrer l'enregistrement. Le shell continue de fonctionner normalement — toutes les commandes que vous exécutez sont capturées.
2. Appuyez sur `CTRL+P, CTRL+P` pour arrêter. La séquence enregistrée est liée à `CTRL+X+CTRL+X`.
3. Appuyez sur `CTRL+X+CTRL+X` à tout moment pour rejouer la séquence complète.

La dernière macro enregistrée est sauvegardée dans `NIXLPER_LAST_MACRO_BINDING_FILE`, ce qui vous permet de la restaurer dans une nouvelle session shell avec `CTRL+P+CTRL+L` sans avoir à la réenregistrer.

---

## Exemple

```bash
# Démarrer l'enregistrement
# (appuyer sur CTRL+P)

cd /var/log
grep -i error syslog | tail -20

# Arrêter l'enregistrement
# (appuyer sur CTRL+P puis CTRL+P)

# Appuyer maintenant sur CTRL+X+CTRL+X pour rejouer ces deux commandes
```

---

[← Retour à l'accueil](index.md)
