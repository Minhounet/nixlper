# Mode débogage

> 🇬🇧 [English version](../feature-debug.md)

Le mode débogage permet d'inspecter la configuration résolue de nixlper et de tracer des appels de fonctions individuels — sans inonder le shell interactif avec un `set -x` global.

---

## Commandes

### Activer/désactiver le mode débogage — `CTRL+X+Z`

```
nixlper_debug_toggle
```

Bascule `NIXLPER_DEBUG` pour la session shell courante.

- **Activé** : affiche un résumé de toutes les variables `NIXLPER_*` résolues.
- **Désactivé** : affiche un message de confirmation.

Pour l'activer de façon permanente, définir `NIXLPER_DEBUG=true` via `nconf`.

---

### Tracer une fonction — `ndebug`

```
ndebug <fonction> [args...]
```

Enveloppe la fonction nixlper nommée dans `set -x` / `set +x` afin que seule l'exécution de cette fonction soit tracée. Cela évite le bruit qu'un `set -x` global produirait dans un shell interactif (readline, `PROMPT_COMMAND` et autres mécanismes internes apparaîtraient sinon dans la sortie).

**Exemples :**

```bash
ndebug navigate
ndebug _check_update
ndebug _display_existing_bookmarks
```

**Format de sortie :**

```
[NIXLPER DEBUG] Tracing: navigate
──────────────────────────────────────────────────────────
+ <lignes tracées>
──────────────────────────────────────────────────────────
[NIXLPER DEBUG] Exit code: 0
```

Si la fonction est introuvable, `ndebug` affiche une erreur et suggère :

```bash
declare -F | grep nixlper   # lister toutes les fonctions nixlper chargées
```

---

### Afficher la configuration — `ndbconf`

```
ndbconf
```

Affiche les valeurs résolues de toutes les variables `NIXLPER_*` sans basculer le mode débogage. Utile pour une inspection ponctuelle.

---

## Configuration

| Variable | Type | Défaut | Description |
|---|---|---|---|
| `NIXLPER_DEBUG` | bool | `false` | Active le mode débogage (résumé de config au démarrage, traçage `ndebug`) |

À définir via `nconf` ou temporairement avec `export NIXLPER_DEBUG=true` dans la session courante.

---

## Raccourcis & alias

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+Z` | — | Activer/désactiver le mode débogage |
| — | `ndebug` | Tracer un appel de fonction unique |
| — | `ndbconf` | Afficher toutes les variables `NIXLPER_*` résolues |
