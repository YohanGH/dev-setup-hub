<!-- **************************************************************************** -->
<!--                                                                              -->
<!--                                                         .--.    No           -->
<!--    CHANGELOG.md                                        |o_o |    Pain        -->
<!--                                                        |:_/ |     No         -->
<!--    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      -->
<!--                                                      (|     | )              -->
<!--    Created: 2026/07/22 by YohanGH                    '__   _/_               -->
<!--                                                     (___)=(___)              -->
<!--                                                                              -->
<!-- **************************************************************************** -->

# Changelog

Tous les changements notables de ce projet sont documentés ici.
Le format s'inspire de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/)
et le versionnage suit [SemVer](https://semver.org/lang/fr/).

## [1.0.0] - 2026-07-22

### Added — Fichiers du dépôt

- `.gitignore` : ignore les fichiers sensibles (clés, secrets, `.env`),
  fichiers OS/éditeur et l'état local Obsidian.
- `README.md` : documentation complète (prérequis, installation rapide,
  détail des scripts, arborescence).
- `SECURITY.md` : politique de sécurité conforme aux conventions GitHub
  (versions supportées, procédure de divulgation responsable).
- `LICENSE.md` : licence **MIT** pour le code du dépôt.

### Added — Scripts d'installation (`scripts/`)

- `install.sh` : orchestrateur interactif enchaînant les 4 étapes
  (option `--yes` pour un déploiement non interactif).
- `init_debian.sh` : vérifie/installe les commandes utiles
  (`curl`, `htop`, `tree`, `fd` [« fs »], `python3`, `tmux`, `zsh`, `git`),
  installe **oh-my-zsh** + **powerlevel10k** + plugins zsh, déploie
  `zshrc` et les alias.
- `install_vim.sh` : déploie le `.vimrc`, installe **vim-plug** et les
  plugins, copie les fichiers de syntaxe. **Prettier désactivé par défaut**
  (`g:prettier#autoformat = 0`).
- `set_header.sh` : installe le header 42 personnalisé et exporte
  `USER` / `MAIL` (version corrigée de l'ancien script).
- `setup_obsidian.sh` : génère le coffre **ANKAMA_OBSIDIAN**.

### Added — Coffre Obsidian ANKAMA_OBSIDIAN

- Arborescence GTD complète (21 dossiers, de `0.Inbox` à `10.Figma`).
- Fichier `2.Activable_OUI/2_minutes_OUI/FAITES_LA.md` (règle des 2 minutes).
- Templates dans `7.Archive/Template/` :
  - `LINT_CONFIG.md` (copié depuis `data_for_obsidian/`),
  - `TEMP_CONTACT.md` (ANNEXE A),
  - `TEMP_NOTE.md` (ANNEXE B),
  - `TEMP_TICKET.md` (nouveau template de suivi de ticket).
- `AI-SECURITY.md` : protection des droits d'auteur et restrictions
  d'usage IA de l'ensemble du coffre.
- `README.md` du coffre décrivant l'organisation GTD.

### Added — Header ANKAMA (`scripts/assets/stdheader.vim`)

- Bannière **ANKAMA** (majuscule, centrée) ajoutée sur les 2 premières
  lignes après le bord d'étoiles.
- Ajout d'une fonction `s:centerline()` pour le centrage sur 80 colonnes.
- Décalage de l'art ASCII (lignes 5→11) et mise à jour de `s:update()`
  (détection de la ligne `Updated:` en ligne 11).
- Rendu vérifié : chaque ligne du header fait exactement 80 caractères.

### Changed

- `install_vim.sh` injecte un bloc idempotent désactivant Prettier
  (formatage manuel uniquement via `:Prettier`).

### Security

- Aucun secret versionné ; `sudo` utilisé uniquement au besoin ;
  chaque commande vérifiée via `command -v` avant installation.
- Sauvegardes automatiques des `~/.zshrc` et `~/.vimrc` existants avant
  écrasement.

[1.0.0]: https://example.com/YohanGH/Configuration_Debian/releases/tag/v1.0.0
