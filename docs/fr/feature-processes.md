# Gestion des processus

> **Tuez n'importe quel processus par nom ou port — de façon interactive, sans chercher les PIDs.**

> 🇬🇧 [English version](../feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Arrêt interactif — choisir par motif ou port |
| `pc PORT` | Vérification rapide de port — nom du processus, PID, ligne de commande, action suggérée (lecture seule) |

---

## Démo

<!-- TODO: ajouter une démo GIF — ik, choisir "par motif", taper "java", confirmer l'arrêt -->

---

## Utilisation

```bash
ik
```

Il vous sera demandé de choisir un mode d'arrêt :

### Arrêt par motif

Saisissez n'importe quelle chaîne — nixlper trouve tous les processus dont le nom ou la ligne de commande correspond, les affiche et demande confirmation avant de les arrêter.

### Arrêt par port

Saisissez un numéro de port — nixlper trouve le processus écoutant sur ce port et propose de l'arrêter.

La détection de port utilise `ss` (iproute2) si disponible, avec `netstat` (net-tools) en repli.

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
Arrêter par [m]otif ou [P]ort ? m
Motif : myapp
  PID 12345 — java -jar myapp.jar
Arrêter le PID 12345 ? [o/N] o
Arrêté.

$ pc 8080
Port 8080 is in use by PID 12345 (node)
Command: node server.js
Suggested action: run 'ik --port 8080' to kill it interactively, or 'kill -9 12345' directly.
```

---

[← Retour à l'accueil](index.md)
