# Diagnostic de santé système

> 🇬🇧 [English version](../feature-system-health.md)

Le diagnostic de santé système interprète les métriques mémoire, disque et CPU et affiche des verdicts en langage clair avec des commandes de remédiation suggérées — sans dépendance externe, sans agent de supervision à installer.

---

## Commandes

### Lancer un diagnostic — `health`

```
health
```

Vérifie trois métriques dans l'ordre :

1. **Mémoire** — via `free`.
2. **Disque** — via `df`, pour chaque système de fichiers monté (les pseudo systèmes de fichiers `tmpfs`, `devtmpfs` et `squashfs` sont ignorés).
3. **CPU** — via la charge moyenne d'`uptime`, ramenée au nombre de cœurs (`nproc`, avec repli sur `/proc/cpuinfo`).

Chaque métrique reçoit l'un des trois verdicts suivants :

| Verdict | Signification |
|---|---|
| `[OK]` | En dessous du seuil WARN |
| `[WARN]` | Au niveau ou au-dessus du seuil WARN |
| `[CRIT]` | Au niveau ou au-dessus du seuil CRIT |

Les lignes `WARN` et `CRIT` listent aussi les principaux consommateurs de ressources (nom du processus, usage, PID) ainsi qu'une commande de remédiation suggérée.

**Exemple de sortie :**

```
──────────────────────────────────────────────────────────
  [NIXLPER HEALTH] System health check
──────────────────────────────────────────────────────────
[WARN] Memory at 87% (14000MB / 16000MB) — top consumers: java (1757.8 MB, pid 1234) → consider: ik or kill -9 <pid>
[CRIT] Disk / at 95% → consider: du -sh /* 2>/dev/null | sort -rh | head
[OK]   CPU load 0.52 on 4 core(s) (13%).
──────────────────────────────────────────────────────────
```

---

## Configuration

| Variable | Type | Défaut | Description |
|---|---|---|---|
| `NIXLPER_HEALTH_WARN_PCT` | int | `80` | Pourcentage à partir duquel une métrique est signalée `[WARN]` |
| `NIXLPER_HEALTH_CRIT_PCT` | int | `90` | Pourcentage à partir duquel une métrique est signalée `[CRIT]` |
| `NIXLPER_HEALTH_TOP_N` | int | `3` | Nombre de principaux consommateurs affichés par métrique `WARN`/`CRIT` |

À définir via `nconf` (`CTRL+X+C`).

---

## Raccourcis & alias

| Raccourci | Alias | Description |
|---|---|---|
| — | `health` | Lancer un diagnostic de santé système |
