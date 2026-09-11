# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    CHANGELOG.md                                        |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2023/12/02 by YohanGH                    '__   _/_               #
#    Updated: 2026/08/29 by YohanGH                   (___)=(___)              #
#                                                                              #
# **************************************************************************** #

# Changelog

## 3.1.0 — 2026-09-11

### Ajouté

- `install/25-vim.sh` — **il n'existait aucune étape Vim**. `./install.sh`
  déployait le plugin d'en-tête et rien d'autre ; seul le script de repli
  `debian/scripts/install_vim.sh` posait un `.vimrc`, depuis sa propre copie.
  La nouvelle étape lie `~/.vimrc` et les syntaxes au dépôt, installe vim-plug
  et lance `:PlugInstall`.
- `checks.conf` : clés `date_macos` / `date_debian`, une sonde qui relève sur
  la machine la date du dernier passage réel. `check.sh` affiche la plus
  récente des deux dates — déclarée ou relevée — et dit laquelle.
- `install/40-obsidian.sh` trouve le coffre tout seul : d'abord les coffres
  qu'Obsidian enregistre dans `obsidian.json`, puis un balayage de `$HOME`.
  Le chemin retenu part dans `~/.zsh_local`, la fois suivante ne demande rien.
- `vim` dans `profiles/common.list` — il n'y figurait pas.

### Corrigé

- **`check.sh` annonçait « jamais enregistré » juste après une mise à jour.**
  Le fichier d'état ne connaissait que ce qu'on lui avait déclaré avec
  `--done`, et personne ne le lance après chaque `apt upgrade`.
- L'audit lynis passait pour absent dès qu'il avait tourné sans `sudo` : la
  preuve ne regardait que `/var/log/lynis.log`, alors que lynis écrit dans
  `$HOME` quand il n'est pas privilégié.
- `lynis show options` réécrit `lynis-report.dat` sans rien auditer. La sonde
  regarde le journal, pas le rapport, et ignore un journal vide.
- Sonder Homebrew pouvait déclencher un `brew update` en douce, ce qu'un outil
  qui promet de ne jamais rien mettre à jour n'a pas le droit de faire :
  `HOMEBREW_NO_AUTO_UPDATE=1` sur la sonde.
- La preuve Debian de `update` mesurait la fraîcheur d'un fichier de log, ce
  que fait désormais la ligne de date. Elle compte maintenant les paquets
  réellement en retard, comme son équivalent macOS.
- `checks_evidence` mourait si un bloc de `checks.conf` omettait une clé.

### Modifié

- **« Header 42 » devient « Header Tux »** : le mécanisme vient du `stdheader`
  de 42, mais l'ASCII art encadré est Tux — « No Pain No Code ».
- `README.md` : la section « Not automated » disparaît, son contenu vit dans
  `docs/MANUAL.md` que la table de documentation référence déjà.

### Supprimé

- `docs/archive/AUDIT_REPORT.md`.

### En cours

- `vim/` — le découpage en fragments couvre un peu plus de la moitié du
  `.vimrc`. `install/25-vim.sh` compte les lignes restantes à chaque
  exécution et passera de lui-même à `vim-builder.sh` quand il n'y en aura
  plus. Les charger avant en doublerait une bonne moitié.
- `debian/Configuration_Vim/` duplique `vim/` : syntaxes identiques au bit
  près, `.vimrc` différent par un plugin eslint et deux mappings.

## 3.0.0 — 2026-08-29

Restructuration complète : le dépôt cible désormais macOS **et** Debian/Ubuntu
depuis une source unique, avec un point d'entrée unique.

### Ajouté

- `install.sh` à la racine : détecte l'OS et enchaîne les étapes. `--list`,
  `--yes`, `--only`, `--help`. Chaque étape reste lançable seule.
- `install/` — huit étapes qui s'enregistrent d'elles-mêmes : il suffit de
  déposer un fichier portant une ligne `# @desc:`.
- `profiles/` — listes de paquets par OS, avec préfixe `!` pour les optionnels.
- `lib/` — socle partagé : `ui.sh` (affichage), `os.sh` (seule frontière
  macOS/Debian), `fs.sh` (liens, copies, sauvegardes), `profile.sh`.
- `external.conf` — dépôts récupérés à l'installation au lieu d'être recopiés.
- `.github/workflows/ci.yml` — shellcheck et shfmt.
- `docs/ARCHITECTURE.md`, `docs/MANUAL.md`, `config/obsidian/plugins.md`.

### Modifié

- Toutes les configs passent sous `config/` : `zsh/`, `editor/`, `header/`,
  `obsidian/`. Une seule copie de chacune.
- `LICENSE` passe de **GPL-2.0 à MIT**, alignée sur ce que les sous-arbres
  déclaraient déjà.
- `config/zsh/zshrc` charge lui-même `~/.zsh_aliases` et `~/.zsh_local`. Ce qui
  est propre à une machine ne va plus dans le fichier versionné.
- `config/editor/` sert **VSCode et VSCodium** à l'identique.
- `.editorconfig` reconnaît enfin les tabulations des scripts shell.

### Corrigé

- `config/editor/settings.json` ne se chargeait pas : trois virgules
  manquantes. Les éditeurs retombaient sur leurs réglages par défaut.
- La séquence `multiCommand.makeRoom` appelait une commande inexistante
  (`Workbench.action.togglesActivityBarVisibility`).
- `keybindings.json` : `ctrl-t` au lieu de `ctrl+t`, une règle `ctrl+s` morte,
  et une paire `alt+down` qui s'annulait elle-même.
- `SECURITY.md` était enveloppé dans une clôture ` ```md ` jamais fermée et
  s'affichait entièrement comme un bloc de code.
- Adresses de contact harmonisées ; le placeholder `conduct@your-domain.tld`
  n'avait jamais été remplacé.

### Supprimé

- `setup/setup-configs.sh` — appelait `print_tree` avant de la définir, shebang
  en ligne 13, et reclonait depuis GitHub les dépôts que ce hub avait absorbés.
  Sa chaîne nvm/Node/prettier survit dans `install/15-node.sh`.
- Doublons de `debian/` : `Configuration_zshrc/` et `Configuration_Header/`
  étaient identiques au bit près à `shell/` et `headers/`.
- Variante ANKAMA du header, au profit du Tux d'origine.
- Sous-arbres `claude/` et `halo/`, désormais dans `external.conf`.
- 22 Mo de plugins Obsidian tiers — inventaire dans
  `config/obsidian/plugins.md`.

### En cours

- `vim/` attend la fin de son découpage en fragments avant de passer sous
  `config/vim/`.
- `debian/scripts/` reste en repli tant que le nouveau chemin n'a pas tourné
  sur une vraie machine Debian.

## 2.0.0

- Fusion of all configs into a single repository. { 'commit' : '6f5f045b' }

## 1.0.0

- Initial commit, first version. { 'commit' : '094c691' }
