# Son

> **Jouez un court air musical via le haut-parleur du PC.**

> 🇬🇧 [English version](../feature-sound.md)

| Alias | Description |
|---|---|
| `tune` | Jouer un court air musical (`success`, `error`, ou `fanfare`) |

---

## Utilisation

```bash
tune [PRESET]
```

`tune` joue un court air musical via le haut-parleur PC local, à l'aide de l'utilitaire
[`beep`](https://github.com/johnath/beep). `PRESET` est optionnel et vaut `success` par défaut ;
les préréglages disponibles sont :

- `success` — un court arpège ascendant
- `error` — deux courtes notes graves descendantes
- `fanfare` — trois notes aiguës rapides suivies d'une note tenue

---

## Important : un son du haut-parleur local, pas une lecture audio

`beep` pilote le haut-parleur PC (ou le périphérique noyau `pcspkr`) de la machine qui exécute
réellement la commande — il ne joue pas de son via la carte son, et n'est pas transmis sur le
réseau.

- **Via SSH, le son retentit sur le serveur distant, pas sur votre ordinateur.** Si vous vous
  connectez en `ssh` puis exécutez `tune`, vous n'entendrez généralement rien en local — l'air
  (s'il est joué) sonne sur la console de la machine distante.
- Nécessite le paquet `beep` installé (`sudo apt install beep` / `sudo dnf install beep`) et un
  accès au haut-parleur PC : le module noyau `pcspkr` chargé, et la permission d'écrire sur le
  périphérique console/evdev (certaines distributions réservent cela à `root` ou à un groupe
  spécifique).
- Si `beep` est absent ou l'accès au haut-parleur refusé, `tune` affiche une erreur expliquant
  pourquoi — il n'échoue jamais silencieusement.

En session locale (hors SSH) avec `beep` installé et l'accès au haut-parleur disponible, cela
fonctionne sans autre dépendance — pas de fichier audio, pas de lecteur multimédia.

---

## Exemple

```bash
$ tune
$ tune error
$ tune fanfare
```

---

## Configuration

Disponible via `nconf` (`CTRL+X+C`) :

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_SOUND_DEFAULT_PRESET` | `success` | Préréglage joué quand `tune` est appelé sans argument |

---

[← Retour à l'accueil](index.md)
