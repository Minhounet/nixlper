# PowerShell (préversion)

> **Vous connaissez bash mais vous êtes coincé dans PowerShell ? Tapez `grep -rn`, `ls -la`, `rm -rf`, `tail -f` : ça marche, avec en plus les signets et la palette de commandes de nixlper sur les mêmes raccourcis `CTRL+X`.**

> 🇬🇧 [English version](../feature-powershell.md)

> ⚠️ **Préversion.** Première version du portage PowerShell. Elle couvre les commandes compatibles bash, les signets et la palette de commandes ; les autres fonctionnalités de nixlper restent réservées à bash. Testée avec PowerShell 7 sous Linux ; écrite pour fonctionner avec Windows PowerShell 5.1 et PowerShell 7 sous Windows, mais pas encore essayée sur Windows. Vos retours sont les bienvenus.

| Raccourci | Alias | Description |
|---|---|---|
| `CTRL+X+A` | `fa` | Palette de commandes : chercher et lancer n'importe quelle commande nixlper |
| `CTRL+X+D` | `bd` | Afficher les signets enregistrés et y accéder |
| `CTRL+X+B` | `bm` | Ajouter ou supprimer un signet pour le dossier courant |
| — | `grep` | Rechercher du texte : `-i -v -n -r -l -c -w -x -o -F -E -e --include` |
| — | `head` / `tail` | Premières / dernières lignes : `-n N`, `-N`, `tail -n +N`, `tail -f` |
| — | `wc` | Compter lignes / mots / octets : `-l -w -c` |
| — | `ls` | Lister : `-a -l -R -t -S -r -1 -d` |
| — | `rm` / `cp` / `mv` | Supprimer / copier / déplacer : `-r -f -i -v` |
| — | `touch` / `which` / `export` | Créer des fichiers, localiser une commande, définir des variables d'environnement |

---

## Installation

Nixlper pour PowerShell est un module PowerShell classique, fourni sous forme de `nixlper-powershell-vX.Y.Z.zip` avec chaque [version GitHub](https://github.com/Minhounet/nixlper/releases) (à partir de la première version publiée après cette préversion).

### Depuis le zip de la version (recommandé)

Téléchargez le zip, puis dans PowerShell (adaptez le nom du fichier) :

```powershell
$zip = "$HOME\Downloads\nixlper-powershell-vX.Y.Z.zip"
# Windows marque les fichiers téléchargés comme venant d'Internet ; sans cette étape, le module est refusé.
# (Windows uniquement : ignorez cette ligne sous Linux/macOS.)
Unblock-File -Path $zip
# Extraire dans votre dossier de modules personnel (la première entrée de PSModulePath, pour PowerShell 7 comme 5.1).
Expand-Archive -Path $zip -DestinationPath ($env:PSModulePath -split [IO.Path]::PathSeparator)[0] -Force
# Le charger dans chaque nouvelle session.
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Add-Content -Path $PROFILE -Value 'Import-Module Nixlper'
```

Ouvrez une nouvelle fenêtre PowerShell. Pour mettre à jour plus tard, relancez les trois premières commandes avec le nouveau zip (`-Force` remplace les anciens fichiers).

### Depuis un clone du dépôt

Pour essayer le code le plus récent avant sa publication :

```powershell
git clone https://github.com/Minhounet/nixlper.git $HOME\nixlper
Add-Content -Path $PROFILE -Value 'Import-Module $HOME\nixlper\src\main\powershell\Nixlper\Nixlper.psd1'
```

Si l'exécution des scripts est bloquée dans l'un ou l'autre cas, autorisez les scripts locaux une fois avec
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

[`fzf`](https://github.com/junegunn/fzf#installation) est facultatif mais recommandé (`winget install fzf`) : avec lui, la palette et le sélecteur de signets deviennent des filtres flous en direct.

---

## Commandes à la bash

PowerShell possède déjà `ls`, `rm`, `cp` et `mv`, mais ce sont des alias vers des commandes PowerShell : `ls -la` ou `rm -rf build` échouent avec *« Impossible de trouver un paramètre »*. Nixlper les remplace (et ajoute `grep`, `head`, `tail`, `wc`, `touch`, `which`, `export`) par des versions qui comprennent les options bash habituelles. Tout est construit sur PowerShell et .NET, aucun programme supplémentaire n'est nécessaire.

```powershell
grep -rn TODO src --include=*.java     # récursif, numéros de ligne, fichiers .java uniquement
grep -i 'error\|warn' app.log          # l'alternative façon bash fonctionne (règles des regex basiques GNU)
Get-Process | grep -w pwsh             # grep sur le texte affiché à l'écran
tail -f app.log                        # suivre un journal qui grossit
ls -1t | head -n 5                     # les 5 noms modifiés le plus récemment
ls | wc -l                             # nombre d'éléments
rm -rf build
cp -r src backup
export JAVA_HOME=C:\tools\jdk-21
```

**Vos habitudes PowerShell continuent de fonctionner.** Quand une commande reçoit des paramètres PowerShell (`ls -Recurse`, `rm -Force`, `cp -Destination x`), nixlper la transmet telle quelle à la commande PowerShell d'origine. Les scripts qui envoient des fichiers dans un pipeline (`Get-ChildItem *.tmp | rm`) fonctionnent aussi.

**Quand est-ce actif ?** Par défaut, uniquement sous Windows. Sous Linux et macOS, les vrais outils existent déjà. Sous Windows, une commande est ignorée lorsqu'un vrai exécutable du même nom est dans votre `PATH` (par exemple via Git for Windows ou uutils), car le vrai outil vaut mieux qu'une émulation. Utilisez `NIXLPER_BASH_COMPAT` pour changer ce comportement (voir plus bas).

**Différences connues avec bash :**
- PowerShell retire un `--` isolé avant que nixlper ne le voie. Pour chercher un motif qui commence par un tiret, utilisez `grep -e -x`.
- `$VAR` est une variable PowerShell. Les variables d'environnement s'écrivent `$env:VAR`, par ex. `export PATH="$env:PATH;C:\tools"`.
- Les expressions régulières sont des regex .NET avec une traduction façon GNU (`\|`, `\(`, `[[:digit:]]`, `\<`, `\>`). De rares constructions propres à GNU, comme les références arrière en mode basique, peuvent se comporter différemment.
- `ls` renvoie des objets fichiers (affichés comme une liste détaillée) pour pouvoir les envoyer à d'autres commandes PowerShell. Utilisez `ls -1` pour n'avoir que les noms.
- Les options de contexte de `grep` (`-A`, `-B`, `-C`) ne sont pas encore prises en charge.

---

## Signets

Même comportement que les [signets bash](feature-bookmarks.md) :

- `CTRL+X+B` (ou `bm`) ajoute un signet pour le dossier courant. Un nom vous est demandé ; le nom du dossier est proposé par défaut. Relancez-le dans un dossier déjà enregistré pour supprimer le signet.
- `CTRL+X+D` (ou `bd`) liste les signets et vous emmène dans l'un d'eux. Avec `fzf`, tapez des chiffres pour aller à une entrée numérotée ou des lettres pour filtrer. Sans `fzf`, tapez le numéro.
- Chaque signet devient aussi une commande : tapez son nom pour y aller. Un signet ne peut jamais masquer une commande existante.

Le fichier de signets utilise **le même format que bash**, un seul fichier peut donc servir aux deux shells. Avec PowerShell sous Linux/macOS, il est partagé avec bash par défaut (`~/.local/share/nixlper/bookmarks`). Sous Windows, ne pointez `NIXLPER_BOOKMARKS_FILE` vers votre fichier bash que si les deux shells utilisent le même type de chemin. Git Bash écrit `/c/Users/...`, que PowerShell ne sait pas ouvrir.

---

## Palette de commandes

`CTRL+X+A` (ou `fa`) liste toutes les commandes nixlper disponibles dans la session, avec leur raccourci, leur catégorie et leur description, et lance celle que vous choisissez. Les commandes qui ont besoin d'arguments (`grep`, `cp`...) les demandent avant de s'exécuter. Les commandes sont découvertes à partir des mêmes annotations `@cmd-palette` que la version bash.

---

## Raccourcis clavier

Les raccourcis sont des accords PSReadLine : appuyez sur `CTRL+X`, relâchez, puis appuyez sur `CTRL+A`, `CTRL+D` ou `CTRL+B`. Chacun remplace la ligne courante par la commande et l'exécute.

> Sous Windows, le mode d'édition par défaut de PSReadLine utilise `CTRL+X` pour **Couper**. Les accords nixlper font de `CTRL+X` une touche préfixe, qui ne coupe donc plus. Si vous en avez besoin, définissez `NIXLPER_PS_KEYBINDINGS=false` et utilisez les alias (`fa`, `bd`, `bm`).

---

## Configuration

Les réglages sont des variables d'environnement. Définissez-les dans `$PROFILE` **avant** la ligne `Import-Module` :

```powershell
$env:NIXLPER_BASH_COMPAT = 'true'
Import-Module $HOME\nixlper\src\main\powershell\Nixlper\Nixlper.psd1
```

| Variable | Défaut | Description |
|---|---|---|
| `NIXLPER_BASH_COMPAT` | `auto` | `auto` : commandes à la bash sous Windows uniquement, sauf celles qui existent comme vrais exécutables. `true` : toujours, pour toutes les commandes. `false` : jamais. |
| `NIXLPER_BOOKMARKS_FILE` | `~/.local/share/nixlper/bookmarks` | Fichier de signets (format bash) |
| `NIXLPER_BOOKMARKS_FUZZY` | `true` | Utiliser `fzf` pour le sélecteur de signets lorsqu'il est installé |
| `NIXLPER_PS_KEYBINDINGS` | `true` | Activer les accords `CTRL+X` |

`Remove-Module Nixlper` remet tout en place : les `ls`/`rm`/`cp`/`mv` d'origine de PowerShell et plus aucune commande de signet.
