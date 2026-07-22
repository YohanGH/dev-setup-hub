<!-- **************************************************************************** -->
<!--                                                                              -->
<!--                                                         .--.    No           -->
<!--    README.md                                           |o_o |    Pain        -->
<!--                                                        |:_/ |     No         -->
<!--    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      -->
<!--                                                      (|     | )              -->
<!--    Created: 2026/07/22 by YohanGH                    '__   _/_               -->
<!--                                                     (___)=(___)              -->
<!--                                                                              -->
<!-- **************************************************************************** -->

# Configuration_Debian

> Scripts d'installation et de configuration **« clé en main »** pour un
> nouveau poste **Debian / Ubuntu** : outils système, shell `zsh`
> (oh-my-zsh + powerlevel10k), éditeur `vim`, header 42 personnalisé
> **ANKAMA**, et génération d'un coffre **Obsidian entreprise**
> `ANKAMA_OBSIDIAN`.

---

## Sommaire

- [Prérequis](#prérequis)
- [Installation rapide](#installation-rapide)
- [Détail des scripts](#détail-des-scripts)
- [Arborescence du dépôt](#arborescence-du-dépôt)
- [Sécurité](#sécurité)
- [Licence](#licence)

---

## Prérequis

- Une distribution **Debian** ou **Ubuntu** (testé sur Debian 12 / Ubuntu 22.04+).
- Un accès `sudo`.
- Une connexion internet (téléchargement des paquets et plugins).

## Installation rapide

```bash
git clone <url-du-repo> Configuration_Debian
cd Configuration_Debian/scripts
chmod +x *.sh

# Tout installer d'un coup (orchestrateur interactif) :
./install.sh
```

L'orchestrateur `install.sh` enchaîne les étapes ci-dessous et vous laisse
choisir celles à exécuter.

### Lancer une étape isolée

```bash
cd scripts

./init_debian.sh      # 1. Outils système + zsh + oh-my-zsh + powerlevel10k
./install_vim.sh      # 2. Configuration Vim (prettier désactivé par défaut)
./set_header.sh       # 3. Header 42 personnalisé "ANKAMA"
./setup_obsidian.sh   # 4. Génère le coffre Obsidian ANKAMA_OBSIDIAN
```

## Détail des scripts

| Script | Rôle |
| ------ | ---- |
| `install.sh` | Orchestrateur : exécute les scripts dans l'ordre, avec confirmations. |
| `init_debian.sh` | Vérifie/installe `curl htop tree fd python3 tmux`, puis `oh-my-zsh` + `powerlevel10k` et déploie `zshrc` + alias. |
| `install_vim.sh` | Déploie `.vimrc`, installe `vim-plug`, lance `PlugInstall`. **Prettier désactivé par défaut.** |
| `set_header.sh` | Installe le plugin `stdheader.vim` avec la bannière **ANKAMA** centrée. Exporte `USER`/`MAIL`. |
| `setup_obsidian.sh` | Crée l'arborescence `ANKAMA_OBSIDIAN`, les templates et le fichier `AI-SECURITY.md`. |

### Notes d'usage Vim

Après `install_vim.sh`, ouvrez `vim` puis `:PlugInstall` si l'installation
automatique n'a pas eu lieu. Le header s'insère avec **`F1`**
(commande `:Stdheader`).

### Coffre Obsidian

Par défaut le coffre est généré dans `~/ANKAMA_OBSIDIAN`. Vous pouvez
préciser une destination :

```bash
./setup_obsidian.sh /chemin/vers/mon/coffre
```

## Arborescence du dépôt

```text
Configuration_Debian/
├── README.md              # Ce fichier
├── SECURITY.md            # Politique de sécurité (norme GitHub)
├── LICENSE.md             # Licence MIT
├── CHANGELOG.md           # Journal des modifications
├── .gitignore             # Ignore les fichiers sensibles
├── scripts/
│   ├── install.sh
│   ├── init_debian.sh
│   ├── install_vim.sh
│   ├── set_header.sh
│   ├── setup_obsidian.sh
│   └── assets/
│       └── stdheader.vim  # Header 42 personnalisé ANKAMA
├── Configuration_Vim/     # Source de la config Vim (.vimrc, syntax/)
├── Configuration_zshrc/   # Source de la config zsh (zshrc, alias)
├── Configuration_Header/  # Source d'origine du header 42
└── data_for_obsidian/     # Modèles Obsidian (LINT_CONFIG.md, ...)
```

## Sécurité

Voir [`SECURITY.md`](SECURITY.md). Aucun secret n'est versionné (cf.
[`.gitignore`](.gitignore)). Le contenu du coffre Obsidian est protégé par
le fichier `AI-SECURITY.md` généré à sa racine.

## Licence

Code sous licence **MIT** — voir [`LICENSE.md`](LICENSE.md).
