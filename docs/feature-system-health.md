# System Health Advisor

> 🇫🇷 [Version française](fr/feature-system-health.md)

The system health advisor interprets memory, disk, and CPU metrics and prints plain-English verdicts with suggested remediation commands — no external dependencies, no monitoring agent to install.

---

## Commands

### Run a health check — `health`

```
health
```

Checks three metrics in order:

1. **Memory** — via `free`.
2. **Disk** — via `df`, once per mounted filesystem (pseudo filesystems `tmpfs`, `devtmpfs`, and `squashfs` are skipped).
3. **CPU** — via `uptime`'s load average, scaled by core count (`nproc`, falling back to `/proc/cpuinfo`).

Each metric gets one of three verdicts:

| Verdict | Meaning |
|---|---|
| `[OK]` | Below the WARN threshold |
| `[WARN]` | At or above the WARN threshold |
| `[CRIT]` | At or above the CRIT threshold |

`WARN` and `CRIT` lines also list the top resource consumers (process name, usage, PID) and a suggested remediation command.

**Example output:**

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

| Variable | Type | Default | Description |
|---|---|---|---|
| `NIXLPER_HEALTH_WARN_PCT` | int | `80` | Percentage at which a metric is reported as `[WARN]` |
| `NIXLPER_HEALTH_CRIT_PCT` | int | `90` | Percentage at which a metric is reported as `[CRIT]` |
| `NIXLPER_HEALTH_TOP_N` | int | `3` | Number of top resource consumers shown per `WARN`/`CRIT` metric |

Set via `nconf` (`CTRL+X+C`).

---

## Keybindings & Aliases

| Shortcut | Alias | Description |
|---|---|---|
| — | `health` | Run a system health check |
