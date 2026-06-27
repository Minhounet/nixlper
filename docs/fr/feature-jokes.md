# Blagues

> **Un jeu de mots geek aléatoire, parce que la vie est trop courte pour des commits sérieux.**

> 🇬🇧 [English version](../feature-jokes.md)

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+K` | `joke` | Afficher une blague ou un jeu de mots développeur |

---

## Fonctionnement

Nixlper embarque une petite sélection de jeux de mots développeur en français et en anglais.
La commande `joke` (ou `CTRL+X+K`) en tire un au hasard dans la liste correspondant à votre langue.

La langue est choisie selon cette priorité :
1. `NIXLPER_JOKE_LANG` si défini à `fr` ou `en`.
2. Détection automatique depuis `$LANG` quand `NIXLPER_JOKE_LANG=auto` (valeur par défaut) : une locale commençant par `fr` utilise la liste française, tout autre locale utilise l'anglais.

---

## Configurer la langue

Définissez `NIXLPER_JOKE_LANG` via `nconf` (`CTRL+X+C`) ou directement dans `~/.config/nixlper/nixlper.conf` :

```bash
export NIXLPER_JOKE_LANG=fr    # toujours en français
export NIXLPER_JOKE_LANG=en    # toujours en anglais
export NIXLPER_JOKE_LANG=auto  # détection depuis $LANG (défaut)
```

---

[← Retour à l'accueil](index.md)
