# Historique des commandes

> **Relancer une commande précédente — saut numéroté ou recherche floue, comme `rd` pour les répertoires.**

> 🇬🇧 [English version](../feature-history.md)

Nécessite [`fzf`](https://github.com/junegunn/fzf#installation) pour le filtre flou (un sélecteur numéroté est utilisé sinon).

---

## Relancer une commande précédente

```bash
lc
```

Ou appuyez sur `CTRL+X+L`.

`lc` lit l'historique de bash lui-même — la même liste que la commande `history` affiche — du
plus récent au plus ancien, dédupliqué pour qu'une commande répétée n'apparaisse qu'une fois (à
sa position la plus récente).

Si [`fzf`](https://github.com/junegunn/fzf#installation) est installé, `lc` ouvre un **filtre
incrémental** qui combine les deux approches — chaque entrée est affichée avec son numéro d'index, donc :
- taper des **chiffres** (ex. `3`) saute directement à l'entrée numérotée correspondante, comme le sélecteur classique ;
- taper des **lettres** (ex. `docker`) filtre la liste en direct par texte de commande.

Utilisez les flèches pour naviguer, `Entrée` pour sélectionner, `Échap` pour annuler. Sans `fzf`
— ou avec le mode flou désactivé — `lc` revient au sélecteur numéroté classique : une liste
simple, saisissez un numéro et appuyez sur Entrée pour la sélectionner.

Dans les deux cas, la commande sélectionnée n'est **jamais exécutée à l'aveugle** : elle est
préchargée sur une invite éditable `Run>` pour que vous puissiez la relire, la modifier, ou vider
la ligne pour annuler avant d'appuyer sur Entrée.

### Démo

```
$ lc
  1) git status
  2) docker ps -a
  3) rm -rf build/
Select [1-3] (Enter to cancel): 3
Run> rm -rf build/
```

### Configuration

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_LAST_COMMAND_MAX` | `50` | Nombre maximum d'entrées d'historique prises en compte |
| `NIXLPER_LAST_COMMAND_FUZZY` | `true` | Utiliser le filtre flou `fzf` quand `fzf` est installé ; `false` force toujours le sélecteur numéroté |

Configurez via `nconf` (`CTRL+X+C`) ou `~/.config/nixlper/nixlper.conf`.

---

[← Retour à l'accueil](index.md)
