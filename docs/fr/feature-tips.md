# Astuces

> **Apprenez les raccourcis Nixlper progressivement — une astuce à la fois.**

> 🇬🇧 [English version](../feature-tips.md)

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+T` | `tip` | Afficher une astuce aléatoire à la demande |

---

## Fonctionnement

Une astuce s'affiche automatiquement à chaque ouverture d'un nouveau shell, en parcourant toutes les astuces disponibles dans l'ordre. Cela vous permet de découvrir progressivement les fonctionnalités sans être submergé.

Utilisez `tip` ou `CTRL+X+T` à tout moment pour voir une autre astuce à la demande.

---

## Désactiver les astuces de démarrage

Si vous préférez un démarrage de shell épuré, désactivez l'astuce automatique dans `nconf` (`CTRL+X+C`) → `NIXLPER_DISABLE_TIPS`, ou ajoutez dans `~/.config/nixlper/nixlper.conf` :

```bash
NIXLPER_DISABLE_TIPS=true
```

La commande `tip` et le raccourci `CTRL+X+T` continuent de fonctionner indépendamment de ce paramètre.

---

[← Retour à l'accueil](index.md)
