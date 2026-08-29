# Architecture

## L'idée en une phrase

Trois questions différentes, trois endroits différents — et l'OS n'est jamais
un répertoire.

| Question | Répond | Contient |
|---|---|---|
| **Quoi** installer ? | `profiles/` | des listes de paquets, une par OS |
| **Comment** l'installer ? | `install/` | une étape par fichier, agnostique OS |
| **Quel contenu** déployer ? | `config/` | tes fichiers de configuration |

## Pourquoi ce découpage

Le dépôt a longtemps mélangé les trois. `debian/` était un répertoire de
premier niveau au même titre que `vim/` et `shell/` — sauf que `debian` est une
**plateforme** et `vim` un **outil**. Il n'existait aucun `macos/` symétrique :
macOS vivait dans `setup/setup-configs.sh`, encore un autre niveau.

Deux modèles mentaux se disputaient une seule arborescence, et chaque config
existait en double : `shell/` et `debian/Configuration_zshrc/` étaient
identiques au bit près, si bien que corriger l'un ne corrigeait pas l'autre.

Séparer les trois axes fait disparaître le problème : il n'y a plus qu'une
copie de chaque config, et l'OS devient une **couche**, pas un dossier.

## La règle qui tient l'ensemble

> **Une étape de `install/` ne teste jamais l'OS.**

Elle appelle `pkg_install`, et `lib/os.sh` traduit vers `brew` ou `apt`. Si tu
écris `if macOS` dans `install/`, c'est que la différence appartient ailleurs :

- une **différence de nom de paquet** → `profiles/macos.list` / `debian.list`
  (c'est le cas de `python`/`python3` et `fd`/`fd-find`) ;
- une **différence de mécanisme** → `lib/os.sh` ;
- un **chemin qui dépend de l'OS** → une fonction locale à l'étape, comme
  `dossier_user()` dans `30-editor.sh`.

## Les briques

```
install.sh                 point d'entrée : détecte l'OS, enchaîne les étapes
│
├── lib/                   socle partagé, sourcé jamais exécuté
│   ├── ui.sh              affichage : bannière, sections, statuts alignés
│   ├── os.sh              LA frontière macOS / Debian
│   ├── fs.sh              déploiement : liens, copies, sauvegardes
│   └── profile.sh         lecture des listes de paquets
│
├── profiles/*.list        quoi installer
├── install/NN-*.sh        comment
├── config/<outil>/        quoi déployer
└── external.conf          dépôts qui restent chez eux
```

### `lib/ui.sh`

Toute sortie passe par lui, pour que les phases soient visuellement séparées.
Il se dégrade seul : glyphes ASCII hors UTF-8, couleurs coupées si `NO_COLOR`
est défini, si la sortie n'est pas un terminal, ou si `TERM=dumb`.

Détail non évident : le padding compte les **caractères**, pas les octets.
`printf '%-16s'` pade en octets et un libellé accentué perd une colonne par
accent.

### `lib/fs.sh` — lien ou copie ?

Deux modes de déploiement, et le choix n'est pas cosmétique :

| | Quand | Pourquoi |
|---|---|---|
| `fs_link` | zsh, header vim | éditer le dépôt suffit, l'effet est immédiat |
| `fs_copy` | VSCode, VSCodium | l'éditeur réécrit son `settings.json` par rename atomique, ce qui **remplacerait le lien** par un fichier ordinaire |

Dans les deux cas, tout fichier existant est archivé en `.bak.<horodatage>`
avant d'être touché.

### Fichiers versionnés vs propres à la machine

`~/.zshrc` est un **lien vers le dépôt** : y écrire depuis un script
modifierait du contenu versionné. Tout ce qui varie d'un poste à l'autre — PATH,
identité du header, chargement de nvm — va donc dans `~/.zsh_local`, qui n'est
jamais versionné et que le `zshrc` source en fin de fichier.

## Ajouter quelque chose

**Un paquet** → une ligne dans `profiles/common.list` si `brew` et `apt` lui
donnent le même nom, sinon dans les deux listes par OS. Préfixe `!` pour
optionnel.

**Une étape** → un fichier `install/NN-nom.sh`. Il s'enregistre tout seul :
`install.sh` trie le répertoire et lit la description sur la ligne `# @desc:`.
Rien d'autre à câbler.

**Un dépôt externe** → une ligne dans `external.conf`. On ne recopie pas un
projet vivant ici : la copie dérive de l'amont dès le premier commit et
personne ne sait plus laquelle fait foi. C'est précisément ce qui était arrivé
à `claude/`.

## Ce qui n'est pas encore rangé

| | Pourquoi |
|---|---|
| `vim/` | son découpage en fragments est en cours ; passera sous `config/vim/` une fois terminé |
| `debian/scripts/` | seul chemin éprouvé sur une vraie Debian, gardé en repli tant que `install/` n'y a pas tourné |
| `config/obsidian/obsidian/plugins/` | 22 Mo de JavaScript tiers compilé, à retirer du HEAD |
