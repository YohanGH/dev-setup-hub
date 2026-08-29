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

## Le thème Tokyo Hack sous VSCodium

VSCode et VSCodium reçoivent **exactement les mêmes** `settings.json`,
`keybindings.json` et liste d'extensions. Une seule chose ne peut pas être
identique, et elle ne dépend pas de nous : les deux éditeurs tirent leurs
extensions de registres différents.

| Éditeur | Registre |
|---|---|
| VSCode | Marketplace Microsoft |
| VSCodium | [Open VSX](https://open-vsx.org/) |

`ajshortt.tokyo-hack`, le thème référencé par `settings.json`, **n'est publié
que sur le marketplace Microsoft**. `install/30-editor.sh` le signale et
poursuit ; VSCodium restera sur son thème par défaut.

Trois façons de s'en sortir :

**1. Installer le `.vsix` à la main** — récupérer le paquet depuis le
marketplace, puis :

```bash
codium --install-extension /chemin/vers/tokyo-hack.vsix
```

**2. Basculer sur un thème présent sur les deux registres.**
`enkia.tokyo-night` est très proche et disponible partout. Il faut alors
changer `workbench.colorTheme` et la clé `[Tokyo Hack]` dans
`config/editor/settings.json`.

**3. Ne rien faire** — VSCodium reste sur son thème par défaut, tout le reste
de la configuration s'applique normalement.

Les six autres extensions de `config/editor/extensions.list` ont été vérifiées
présentes sur Open VSX : elles s'installent des deux côtés.

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

### L'exception : KeePassXC

**KeePassXC est la seule application graphique automatisée des deux côtés**,
parce qu'il est dans les **dépôts officiels Debian et Ubuntu** : aucune source
tierce à ajouter, et les correctifs de sécurité arrivent par la distribution.

| | Canal retenu | Version |
|---|---|---|
| macOS | `brew install --cask keepassxc` | 2.7.12 |
| Debian 12 · 13 | `apt install keepassxc` | 2.7.4 · 2.7.10 |
| Ubuntu 22.04 · 24.04 · 25.04 | `apt install keepassxc` | 2.6.6 · 2.7.6 · 2.7.9 |

Flathub livrerait 2.7.12 partout, mais imposerait d'installer flatpak **et**
d'ajouter un dépôt tiers. Recevoir les correctifs par la distribution vaut mieux
que courir après la dernière version.

> **À savoir si tu partages la même base entre les deux postes.**
> Le format **KDBX 4.1** est apparu avec KeePassXC 2.7.0. Une base enregistrée
> en 4.1 par le macOS (2.7.12) **ne s'ouvrira pas** sous Ubuntu 22.04, qui est
> resté en 2.6.6. Garde la base en **KDBX 4.0** tant que les deux postes ne
> sont pas en 2.7 — c'est un choix au moment de créer la base, modifiable
> ensuite dans *Base de données → Paramètres → Sécurité*.

La base elle-même n'est évidemment pas versionnée : `.gitignore` exclut
`*.kdbx` et `*.kdb`. Même chiffrée, une base commitée resterait pour toujours
dans l'historique.

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
