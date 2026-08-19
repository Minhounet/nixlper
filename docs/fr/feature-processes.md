# Gestion des processus

> **Tuez n'importe quel processus par nom ou port — de façon interactive, sans chercher les PIDs.**

> 🇬🇧 [English version](../feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Arrêt interactif — choisir par motif ou port |
| `pc PORT` | Vérification rapide de port — nom du processus, PID et action suggérée |

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

Saisissez un numéro de port — nixlper recherche le processus qui écoute dessus et affiche
son nom, son PID et une action suggérée, sans proposer de le tuer.

```bash
pc 8080
```

Si le port est libre, nixlper l'indique et ne fait rien d'autre.

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
Port 8080 -> process 'java' (PID 12345)
UID   PID  PPID  C STIME TTY TIME     CMD
user  12345 1    0 10:00 ?  00:00:05 java -jar myapp.jar
Suggested action: run 'ik --port 8080' to kill it interactively, or 'kill -9 12345' directly.
```

---

[← Retour à l'accueil](index.md)
