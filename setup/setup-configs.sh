# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    setup-configs.sh                                    |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2024/02/04 15:04:28 by YohanGH           '__   _/_               #
#    Updated: 2024/02/12 10:12:27 by YohanGH          (___)=(___)              #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

echo "Début de la configuration de l'environnement..."

echo "\n --------------------------------------------------------------------- \n"

# Vérification et installation de Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew est déjà installé."
fi

echo "\nMise à jour de Homebrew..."
brew update

# Liste des dépendances à installer

echo "\n ----- \n"
echo "Installation des dépendances nécessaires..."
echo "\n ----- \n"

declare -a dependencies=("git" "curl" "tree" "htop" "tldr" "jq" "fzf" "httpie" "tmux" "python3")

for app in "${dependencies[@]}"; do
    echo "Installation/Verification de ${app}..."
    brew install $app
done

echo "Toutes les dépendances nécessaires ont été vérifiées et installées."

echo "\n --------------------------------------------------------------------- \n"

# Fonction pour vérifier la réussite du clonage/mise à jour
check_success() {
    if [ $? -eq 0 ]; then
        echo "Succès."
    else
        echo "Une erreur s'est produite. Vérifiez les messages d'erreur ci-dessus."
        exit 1
    fi
}

echo "\n ----- \n"

# Fonction pour cloner ou mettre à jour un dépôt
clone_or_update_repo() {
    local repo_url=$1
    local target_dir=$2
    local repo_name=$(basename $repo_url)

    echo -e "\nTraitement de $repo_name..."

    if [ -d "$target_dir/.git" ]; then
        echo -e "\nMise à jour du dépôt $repo_name..."
        git -C "$target_dir" pull
        check_success
    else
        echo -e "\nClonage du dépôt $repo_name vers $target_dir..."
        git clone $repo_url "$target_dir"
        check_success
    fi
}

echo "\n ----- \n"
# Installation d'Oh My Zsh

echo "\nInstallation de nvm (Node Version Manager)..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    # Charger nvm sans redémarrer le terminal
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    check_success
else
    echo "nvm est déjà installé."
fi

echo "\n ----- \n"

# S'assure que nvm est chargé pour ce script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "\n ----- \n"
# Installation de Node.js

echo "\nInstallation de la dernière version de Node.js via nvm..."
nvm install node
nvm use node

echo "\n ----- \n"
# Instalation de Prettier

echo "\nInstallation de Prettier..."
npm install -g prettier


# Configuration pour zshrc et Vim
CONFIG_ZSHRC_URL="https://github.com/YohanGH/Configuration_zshrc"
CONFIG_VIM_URL="https://github.com/YohanGH/Configuration_Vim"
CONFIG_ZSHRC_DIR="$HOME/.config/zsh"
CONFIG_VIM_DIR="$HOME/.vim"

# Téléchargement et installation de plugins zsh et Powerlevel10k
ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Création des répertoires s'ils n'existent pas
mkdir -p $CONFIG_ZSHRC_DIR
mkdir -p $CONFIG_VIM_DIR

# Téléchargez et configurez zshrc, Vim, zsh-autosuggestions, et zsh-syntax-highlighting
clone_or_update_repo $CONFIG_ZSHRC_URL $CONFIG_ZSHRC_DIR
clone_or_update_repo $CONFIG_VIM_URL $CONFIG_VIM_DIR
clone_or_update_repo https://github.com/zsh-users/zsh-autosuggestions $ZSH_AUTOSUGGESTIONS_DIR
clone_or_update_repo https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_SYNTAX_HIGHLIGHTING_DIR

echo "\n ----- \n"

# Téléchargez et installez Powerlevel10k
echo -e "\nInstallation de Powerlevel10k..."
if [ ! -d "$P10K_DIR/.git" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $P10K_DIR
    check_success
else
    echo "Powerlevel10k est déjà installé."
fi

echo "\n ----- \n"

# Déplacez les fichiers de configuration, s'ils existent
echo -e "\nDéplacement des fichiers de configuration zshrc"

if [ -f "$CONFIG_ZSHRC_DIR/zshrc" ]; then
    cp "$CONFIG_ZSHRC_DIR/zshrc" "$HOME/.zshrc"
	check_success
else
    echo "Le fichier zshrc est introuvable, vérifiez le dépôt $CONFIG_ZSHRC_URL."
fi

echo "\n ----- \n"

echo -e "\nDéplacement des fichiers de configuration vimrc"


if [ -f "$CONFIG_VIM_DIR/.vimrc" ]; then
    cp "$CONFIG_VIM_DIR/.vimrc" "$HOME/.vimrc"
	check_success
else
    echo "Le fichier vimrc est introuvable, vérifiez le dépôt $CONFIG_VIM_URL."
fi

echo "\n ----- \n"

# Après la fonction clone_or_update_repo pour CONFIG_ZSHRC_DIR
if [ -f "$CONFIG_ZSHRC_DIR/my-alias.zsh" ]; then
    echo "Déplacement de my-alias.zsh vers le dossier des alias Zsh..."
    cp "$CONFIG_ZSHRC_DIR/my-alias.zsh" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/aliases.zsh"
    check_success
else
    echo "Le fichier my-alias.zsh est introuvable dans $CONFIG_ZSHRC_DIR."
fi

echo "\n --------------------------------------------------------------------- \n"

# Emplacement de base pour la création de l'arborescence GTD
BASE_DIR="$HOME/Documents/GTD"

# Liste des chemins de dossiers à créer
declare -a FOLDERS=(
    "1_In-Box"
    "Activable-NON/Incubation"
    "Activable-NON/Références/Contacts/Professionnelle"
    "Activable-NON/Références/Contacts/Personnel"
    "Activable-NON/Références/DataBase"
    "Activable-NON/Références/Documents/Textuel"
    "Activable-NON/Références/Documents/images"
    "Activable-NON/Références/Documents/PDF"
    "Activable-NON/Références/Documents/Autres"
    "Activable-NON/Références/Livres"
    "Activable-OUI/EnAttente/Professionnel"
    "Activable-OUI/EnAttente/Personnel"
    "Activable-OUI/Projets/Professionnel/DevOps"
    "Activable-OUI/Projets/Professionnel/Docker"
    "Activable-OUI/Projets/Professionnel/Testing"
    "Activable-OUI/Projets/Professionnel/GitHub"
    "Activable-OUI/Projets/Professionnel/Administration"
    "Activable-OUI/Projets/Personnel/DevOps"
    "Activable-OUI/Projets/Personnel/Docker"
    "Activable-OUI/Projets/Personnel/Testing"
    "Activable-OUI/Projets/Personnel/GitHub"
    "Activable-OUI/Projets/Personnel/Administration"
    "Activable-OUI/Sous-Traitez/En Attente"
    "Liste-Contrôle"
    "Idées-Réflexions/Post-it"
    "Archives/Note-Quotidienne"
    "Archives/Professionnel"
    "Archives/Agenda"
    "Archives/Personnel"
    "Template"
)

echo "\n ----- \n"

echo "Création de l'arborescence GTD dans $BASE_DIR :"

echo "\n ----- \n"

# Création de l'arborescence
for folder in "${FOLDERS[@]}"; do
    mkdir -p "$BASE_DIR/$folder"
    print_tree "$folder"
done

echo "\n ----- \n"

# Fonction pour afficher l'arborescence avec `tree`
print_tree() {
    local base_dir=$1
    if command -v tree >/dev/null 2>&1; then
        tree -C "$base_dir"
    else
        echo "La commande 'tree' n'est pas installée, affichage simplifié :"
        find "$base_dir" -print | sed -e 's;[^/]*/;|---;g;s;---|; |;g'
    fi
}

echo "L'arborescence GTD a été créée avec succès dans $BASE_DIR."

echo "\n --------------------------------------------------------------------- \n"

echo -e "\nConfiguration terminée."
