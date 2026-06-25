# Gestion des processus

> **Tuez n'importe quel processus par nom ou port — de façon interactive, sans chercher les PIDs.**

> 🇬🇧 [English version](../feature-processes.md)

| Alias | Description |
|---|---|
| `ik` | Arrêt interactif — choisir par motif ou port |

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

---

## Exemple

```bash
$ ik
Arrêter par [m]otif ou [P]ort ? m
Motif : myapp
  PID 12345 — java -jar myapp.jar
Arrêter le PID 12345 ? [o/N] o
Arrêté.
```

---

[← Retour à l'accueil](index.md)
