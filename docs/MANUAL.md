# Ce qui reste manuel

Tout n'est pas automatisé, et c'est délibéré. Cette page liste ce que
`install.sh` ne fera pas, et pourquoi.

---

## Navigateurs

**Exclus de l'installation automatique, sur demande.**

| | |
|---|---|
| [Safari](https://www.apple.com/safari/) | fourni avec macOS |
| [Chrome](https://www.google.com/chrome/) | [téléchargement](https://www.google.com/chrome/) |
| [Brave](https://brave.com/) | [téléchargement](https://brave.com/download/) |

Un navigateur porte des sessions, des extensions et des mots de passe. Le
réinstaller par script sur un poste déjà en service risque d'écraser un profil
existant, et l'installation elle-même ne prend qu'une minute. Le rapport
bénéfice / risque ne justifie pas l'automatisation.

---

## Applications graphiques sous Debian / Ubuntu

Sous macOS, `install/00-packages.sh` les installe via Homebrew cask
(`profiles/macos-cask.list`). Sous Debian, **chacune exige son propre dépôt
tiers ou un `.deb` téléchargé à la main.** Ajouter cinq sources APT non
vérifiées à un poste de travail est un risque d'approvisionnement que ce dépôt
ne prend pas à ta place.

| Application | Installation sous Debian / Ubuntu |
|---|---|
| [Ghostty](https://ghostty.org/docs/install/binary#linux) | `.deb` depuis les releases officielles |
| [VSCodium](https://vscodium.com/) | dépôt `paulcarroty` — voir la [procédure officielle](https://vscodium.com/#install) |
| [Obsidian](https://obsidian.md/) | `.deb` ou AppImage depuis le site |
| [BeeKeeper Studio](https://www.beekeeperstudio.io/) | `.deb` ou dépôt officiel |
| [Docker](https://docs.docker.com/desktop/setup/install/linux/ubuntu/) | dépôt Docker officiel — suivre la doc amont |
| [Claude Code](https://code.claude.com/docs/fr/agent-view) | voir la doc officielle |

Une fois installées, leurs configurations versionnées se déploient normalement
par `install.sh`.

## Sécurité et maintenance

| Outil | Statut |
|---|---|
| [lynis](https://github.com/cisofy/lynis) | automatisé, optionnel (`profiles/common.list`) |
| [openSCAP](https://github.com/openscap) | automatisé, optionnel sous Debian (`openscap-scanner`) |
| [uCareSystem](https://github.com/Utappia/uCareSystem) | **manuel** — distribué par PPA Ubuntu, absent des dépôts Debian |

---

## Actions qui demandent ton mot de passe

`install.sh` ne les fait pas à ta place : elles modifient des réglages système
ou demandent une authentification interactive.

```bash
# Faire de zsh ton shell par défaut
chsh -s "$(command -v zsh)"
```

```bash
# Configurer l'apparence du prompt powerlevel10k
p10k configure
```

Sous macOS, Homebrew doit être présent avant la première exécution. Son
installeur demande une confirmation et les outils en ligne de commande Xcode :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
