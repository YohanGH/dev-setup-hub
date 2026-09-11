# dev-setup-hub — conventions

Configuration d'environnement de développement pour **deux postes** : macOS et
Debian/Ubuntu. Un seul dépôt, une seule source par outil, l'OS détecté et jamais
choisi.

## La règle qui tient l'architecture

> **Une étape de `install/` ne teste jamais l'OS.**

Elle appelle `pkg_install`, et `lib/os.sh` traduit vers `brew` ou `apt`. Écrire
`if macOS` dans `install/` est le signe que la différence appartient ailleurs :

| Nature de la différence | Où elle va |
|---|---|
| nom de paquet | `profiles/macos.list` / `profiles/debian.list` |
| mécanisme d'installation | `lib/os.sh` |
| chemin dépendant de l'OS | fonction locale à l'étape, cf. `dossier_user()` dans `30-editor.sh` |

## Où va quoi

| Tu veux… | Édite |
|---|---|
| installer un paquet | `profiles/*.list` — préfixe `!` pour optionnel |
| ajouter une étape | `install/NN-nom.sh` — elle s'enregistre seule |
| changer la config d'un outil | `config/<outil>/` |
| partager de la logique | `lib/` |
| récupérer un dépôt externe | `external.conf` |

Une étape s'enregistre en existant : `install.sh` trie `install/` et lit la
description sur la ligne `# @desc:`. Rien à câbler ailleurs.

## Style shell

- **Tabulations**, pas d'espaces. C'est ce qu'utilisent tous les scripts, c'est
  le défaut de `shfmt`, et `.editorconfig` le déclare pour `*.sh`.
- **bash**, pas POSIX sh — `lib/` utilise des tableaux et `local`.
- Toute étape commence par `set -euo pipefail`.
- Toute sortie passe par `lib/ui.sh`. Pas de `echo` brut dans une étape.
- Toute étape est **idempotente** : une seconde exécution annonce « déjà
  présent » au lieu de refaire le travail.
- Rien n'est écrasé sans `fs_backup` au préalable.

`shellcheck` et `shfmt -d` tournent sur `lib/`, `install/` et `install.sh`, à la
fois en CI et dans le hook local avant commit.

## Lien ou copie ?

Le choix n'est pas cosmétique :

- `fs_link` quand l'outil ne réécrit pas son fichier — zsh, plugin vim.
  Éditer le dépôt suffit, l'effet est immédiat.
- `fs_copy` quand il le réécrit — VSCode et VSCodium sauvegardent
  `settings.json` par rename atomique, ce qui **remplacerait le lien** par un
  fichier ordinaire.

## Versionné ou propre à la machine

`~/.zshrc` est un **lien vers le dépôt**. Y écrire depuis un script modifierait
du contenu versionné.

Tout ce qui varie d'un poste à l'autre — PATH, identité, chargement de nvm,
jetons — va dans `~/.zsh_local`, jamais versionné, que le `zshrc` source en fin
de fichier.

## Ce qu'on ne fait pas ici

- Recopier un dépôt vivant. Il dérive de l'amont dès le premier commit et
  personne ne sait plus lequel fait foi. `external.conf` est là pour ça.
- Versionner des artefacts de build appartenant à d'autres projets.
- Ajouter une source APT tierce sans que ce soit un choix explicite et
  documenté dans `docs/MANUAL.md`.
- Exécuter à la place de l'utilisateur ce qui demande son mot de passe ou
  modifie un réglage système — `chsh`, l'installeur Homebrew. On donne la
  commande.

## Documentation

| | |
|---|---|
| `docs/ARCHITECTURE.md` | les trois axes, en détail |
| `docs/MANUAL.md` | ce qui reste manuel, et pourquoi |
| `CONTRIBUTING.md` | conventions, ajout d'une étape |
| `REFACTOR_PLAN.md` | travail en cours |

## En cours, à ne pas déranger

- `vim/` — découpage en fragments en cours côté utilisateur. Ne pas déplacer ni
  réécrire tant que ce n'est pas terminé.
- `debian/scripts/` — seul chemin éprouvé sur une vraie Debian, gardé en repli
  tant que `install/` n'y a pas tourné.
