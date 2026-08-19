# Logs

> **Suivez un fichier de log et mettez en évidence les lignes qui vous intéressent.**

> 🇬🇧 [English version](../feature-logs.md)

| Alias | Description |
|---|---|
| `logtail` | Suivre un fichier, n'afficher que les lignes correspondant à un motif, surlignées |

---

## Utilisation

```bash
logtail FICHIER MOTIF
```

`logtail` encapsule `tail -F FICHIER | grep --color MOTIF` : il suit `FICHIER` (résiste à
la rotation des logs, car il utilise `tail -F`) et n'affiche que les lignes correspondant à
`MOTIF`, avec la correspondance surlignée en couleur. Appuyez sur `CTRL+C` pour arrêter.

`MOTIF` est une expression régulière étendue (`grep -E`).

---

## Exemple

```bash
$ logtail /var/log/app.log "ERROR|WARN"
2026-08-19 10:03:21 ERROR Connection refused
2026-08-19 10:03:45 WARN  Retry attempt 2
```

---

## Configuration

Disponible via `nconf` (`CTRL+X+C`) :

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_LOGTAIL_IGNORE_CASE` | `false` | Correspondance de motif insensible à la casse |
| `NIXLPER_LOGTAIL_LINES` | `10` | Lignes initiales affichées avant de suivre |

---

[← Retour à l'accueil](index.md)
