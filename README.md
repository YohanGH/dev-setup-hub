```
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    README.md                                           |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2024/02/05 08:57:27 by YohanGH           '__   _/_               #
#    Updated: 2024/02/05 10:47:50 by YohanGH          (___)=(___)              #
#                                                                              #
# **************************************************************************** #
```
---


[IMPORTANT] : FIX : CONFIGS-PATH.SH AND SETUP-CONFIGS-Opti.SH

- Err L57 : configs-path (code fonctionnel)
- Err : Permission Setup-config-opti (Dependance Homebrew)


---

# Configuration de l'Environnement macOS pour le Développement

Ce dépôt contient un script Bash pour configurer automatiquement un nouvel environnement de développement sur macOS. Il installe et configure des outils essentiels pour le développement, incluant des utilitaires de ligne de commande, des applications communes utilisées par les développeurs, et des configurations personnalisées pour améliorer l'efficacité du terminal et de l'éditeur de code.

## Fonctionnalités

Le script automatise les tâches suivantes :

- Installation de Homebrew, le gestionnaire de paquets pour macOS.
- Installation des outils de ligne de commande essentiels : `git`, `curl`, `tree`, `htop`, `tldr`, `jq`, `fzf`, `httpie`, `tmux`, et `python3`.
- Installation et configuration de `nvm` (Node Version Manager) pour gérer les versions de Node.js.
- Installation de la dernière version de Node.js et de `Prettier`, un outil de formatage de code.
- Configuration de `zsh` avec Oh My Zsh, incluant des plugins comme `zsh-autosuggestions` et `zsh-syntax-highlighting`, et le thème `Powerlevel10k`.
- Configuration de Vim avec des fichiers `.vimrc` personnalisés pour une expérience de codage améliorée.
- Création d'une arborescence GTD (Getting Things Done) pour une organisation optimale des projets et documents.

## Prérequis

- macOS
- Accès à Internet pour télécharger les paquets et outils nécessaires.

## Utilisation

1) Configuration PATH :

1. Téléchargez le script `setup-config.sh` depuis ce dépôt.
2. Ouvrez le Terminal.
3. Accordez les droits d'exécution au script avec la commande :
    ```
    chmod +x setup-config.sh
    ```
4. Exécutez le script avec :
    ```
    ./setup-config.sh
    ```
5. Suivez les instructions à l'écran pour terminer la confi

2) Setup Configuration Opti :

1. Téléchargez le script `setup-config.sh` depuis ce dépôt.
2. Ouvrez le Terminal.
3. Accordez les droits d'exécution au script avec la commande :
    ```
    chmod +x setup-config.sh
    ```
4. Exécutez le script avec :
    ```
    ./setup-config.sh
    ```
5. Suivez les instructions à l'écran pour terminer la confi :

1. Téléchargez le script `setup-config.sh` depuis ce dépôt.
2. Ouvrez le Terminal.
3. Accordez les droits d'exécution au script avec la commande :
    ```
    chmod +x setup-config.sh
    ```
4. Exécutez le script avec :
    ```
    ./setup-config.sh
    ```
5. Suivez les instructions à l'écran pour terminer la configuration.

## Personnalisation

Vous pouvez personnaliser ce script en modifiant la liste des dépendances dans la section dédiée du script. Ajoutez ou retirez des outils selon vos besoins de développement spécifiques. Le script est conçu pour être facilement modifiable pour inclure des outils supplémentaires ou ajuster les configurations existantes.

## Contribution

Les contributions à ce script sont les bienvenues. Si vous avez des suggestions d'amélioration ou des outils supplémentaires à inclure, n'hésitez pas à créer une issue ou un pull request.

## Licence

Ce script est distribué sous la licence GPL. Voir le fichier `LICENSE` pour plus de détails.


