# Mises à jour

> **Nixlper vérifie les nouvelles versions automatiquement et peut se mettre à jour lui-même.**

> 🇬🇧 [English version](../feature-updates.md)

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+W` | `nu` | Vérifier immédiatement si une nouvelle version est disponible |
| `CTRL+X+G` | `nw` | Afficher les travaux en cours prévus pour la prochaine version |

---

## Démo

<!-- TODO: ajouter une démo GIF — nu affichant "nouvelle version disponible", puis exécution de la commande de mise à jour -->

---

## Canaux

| Canal | Comportement |
|---|---|
| `stable` (défaut) | Suit les versions taguées — notifie quand un tag plus récent existe |
| `edge` | Suit le dernier commit sur `main` — pré-version continue, reconstruite à chaque push |
| `off` | Désactive toutes les vérifications et l'accès réseau |

### Installer sur le canal edge

```bash
curl -fsSL https://raw.githubusercontent.com/Minhounet/nixlper/main/install.sh | bash -s -- --channel edge
```

---

## Vérifications automatiques

Une vérification s'exécute au démarrage du shell, limitée par `NIXLPER_UPDATE_CHECK_INTERVAL` (défaut : une fois par jour).

Hors ligne, la vérification est ignorée silencieusement — la sonde est limitée par `NIXLPER_UPDATE_TIMEOUT` (défaut : 2 secondes) et ne se bloque jamais.

---

## Travaux en cours (`nw`)

```bash
nw
```

Récupère les notes de la pré-version edge depuis GitHub et affiche les commits depuis le dernier tag stable. Permet de voir ce qui est en cours de développement avant la prochaine version.

---

## Configuration

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_UPDATE_CHANNEL` | `stable` | `stable` / `edge` / `off` |
| `NIXLPER_UPDATE_CHECK` | `true` | Activer/désactiver les vérifications automatiques |
| `NIXLPER_UPDATE_AUTO` | `false` | Installer automatiquement les mises à jour (défaut : notification uniquement) |
| `NIXLPER_UPDATE_CHECK_INTERVAL` | `86400` | Secondes entre les vérifications automatiques |
| `NIXLPER_UPDATE_TIMEOUT` | `2` | Délai d'expiration de la sonde réseau en secondes |

Configurable via `nconf` (`CTRL+X+C`).

---

[← Retour à l'accueil](index.md)
