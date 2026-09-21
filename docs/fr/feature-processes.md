# Gestion des processus

> **Arrêtez n'importe quel processus par nom ou par port — un seul sélecteur flou, sans chercher les PIDs.**

> 🇬🇧 [English version](../feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Arrêt interactif — un sélecteur flou qui filtre sur la commande, le PID **et** le port |
| `ik MOTIF` | Le même sélecteur, ouvert pré-filtré sur `MOTIF` |
| `ik --pattern VALEUR` / `ik --port VALEUR` | Modes explicites, sans le sélecteur |
| `pc PORT` | Vérification rapide de port — nom du processus, PID, ligne de commande, action suggérée (lecture seule) |

---

## Démo

<!-- TODO: ajouter une démo GIF — ik, taper 8080, marquer un second processus avec TAB, ENTRÉE, confirmer -->

---

## Utilisation

```bash
ik
```

Aucun mode à choisir. `ik` liste tous les processus dans un unique sélecteur `fzf`, où chaque
ligne porte le PID, les ports écoutés, l'utilisateur et la ligne de commande complète :

```
  PID     PORTS           USER       COMMAND
> 1234    :8080,:9090     user       java -jar myapp.jar
  5678    -               user       node worker.js
  9012    :5432           postgres   postgres -D /var/lib/pgsql/data

  3/187
  Kill > 8080
  Filter by command, PID or port | TAB: mark several | ENTER: validate | ESC: cancel
```

Comme le port figure sur la même ligne que la commande, **une seule saisie cherche dans les
deux** : tapez `8080` si vous ne connaissez que le port, `java` si vous ne connaissez que le
nom, `1234` si vous avez le PID. Plus besoin de décider selon quel critère vous cherchez.

- `TAB` marque plusieurs processus, `ENTRÉE` valide.
- Les processus marqués sont réaffichés et confirmés avant tout arrêt.
- `ÉCHAP` annule.
- Votre propre shell n'apparaît jamais dans la liste — impossible de tuer votre session par
  mégarde.

La détection de port utilise `ss` (iproute2) si disponible, avec `netstat` (net-tools) en repli.
Si aucun des deux n'est installé, la colonne des ports affiche simplement `-` et le sélecteur
continue de filtrer par commande.

### Pré-filtrage

```bash
ik java
```

Ouvre le même sélecteur avec `java` déjà saisi dans la recherche.

### Modes explicites

Les options historiques restent disponibles — pratiques quand vous savez déjà exactement ce que
vous voulez, ou pour une commande en une ligne :

```bash
ik --port 8080      # arrêter ce qui écoute sur 8080
ik --pattern java   # ancien flux d'arrêt par motif, avec liste numérotée
```

Sans `fzf` — ou avec `NIXLPER_KILL_FUZZY=false` (via `nconf`) — `ik` revient au flux historique
qui demande un mode d'arrêt (port/pattern) puis une valeur.

### Vérification rapide de port

`pc PORT` indique ce qui écoute sur un port sans rien arrêter — nom du processus, PID, ligne de
commande complète, et une action suggérée (arrêt via `ik --port` ou `kill -9`). Utile pour
identifier rapidement ce qui occupe un port avant de décider quoi en faire.

```bash
pc 8080
```

Définissez `NIXLPER_PORT_CHECK_SHOW_CMDLINE=false` (via `nconf`) pour masquer la ligne de
commande complète dans la sortie, par exemple sur des systèmes partagés où elle pourrait
révéler des arguments sensibles.

---

## Exemple

```bash
$ ik
# taper « 8080 », TAB pour marquer aussi le worker obsolète, ENTRÉE

About to kill 2 process(es):
  1234    :8080,:9090     user       java -jar myapp.jar
  5678    -               user       node worker.js

Kill process(es) above with kill -9? (y/n, default is n)y
Killed 1234
Killed 5678
-> DONE

$ pc 8080
Port 8080 is in use by PID 12345 (node)
Command: node server.js
Suggested action: run 'ik --port 8080' to kill it interactively, or 'kill -9 12345' directly.
```

---

## Réglages

| Variable | Défaut | Effet |
|---|---|---|
| `NIXLPER_KILL_FUZZY` | `true` | Utiliser le sélecteur `fzf` unifié pour `ik` quand `fzf` est installé |
| `NIXLPER_PORT_CHECK_SHOW_CMDLINE` | `true` | Afficher la ligne de commande complète dans la sortie de `pc` |

---

[← Retour à l'accueil](index.md)
