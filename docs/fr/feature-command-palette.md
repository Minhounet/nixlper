# Palette de commandes

> **La façon la plus rapide de découvrir et d'exécuter n'importe quelle commande Nixlper.**
> Inutile de mémoriser les raccourcis — ouvrez simplement la palette et tapez.

> 🇬🇧 [English version](../feature-command-palette.md)

| Raccourci | Alias |
|---|---|
| `CTRL+X+A` | `fa` |

Nécessite [`fzf`](https://github.com/junegunn/fzf#installation).

---

## Ce qu'elle fait

Ouvre un popup de recherche floue listant toutes les commandes Nixlper disponibles avec :
- Description
- Catégorie
- Raccourci clavier
- Alias

Tapez n'importe quel mot — nom de commande, description ou catégorie — et la liste se filtre instantanément.
Appuyez sur **Entrée** pour exécuter la commande sélectionnée.

---

## Démo

<!-- TODO: ajouter une démo GIF — ouvrir la palette, taper "signet", sélectionner "afficher les signets", appuyer sur Entrée -->

---

## Exécution des commandes

La palette gère deux types de commandes différemment :

- **Commandes simples** — exécutées immédiatement à la sélection (ex. afficher les signets, afficher le logo).
- **Commandes nécessitant des arguments ou une saisie interactive** — placées sur votre ligne de commande pour que vous puissiez taper les arguments et appuyer sur Entrée. Ces commandes sont marquées `@args` ou `@interactive` dans le code source.

Cette distinction existe parce que la palette s'exécute dans le mode brut de readline, où le builtin `read` ne peut pas recevoir de frappes. Placer la commande sur la ligne vous permet d'utiliser la complétion TAB normale.

---

## Astuces

- Appuyez sur `ESC` pour fermer la palette sans rien exécuter.
- Vous pouvez rechercher par catégorie (ex. taper `navigation` ou `macro`).
- Toute nouvelle fonctionnalité que vous ajoutez via des scripts personnalisés avec des annotations `@cmd-palette` apparaît automatiquement ici.

---

[← Retour à l'accueil](index.md)
