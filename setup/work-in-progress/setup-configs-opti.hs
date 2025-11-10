# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    setup-configs-opti.hs                               |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2024/02/12 10:26:56 by YohanGH           '__   _/_               #
#    Updated: 2024/02/12 11:17:58 by YohanGH          (___)=(___)              #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

echo "----------------------------------------------- /n"
echo "Début de la configuration de l'environnement..."
echo "----------------------------------------------- /n"


# Fonction pour afficher un message de début d'opération
start_operation() {
    echo -e "\n[INFO] Début de l'opération : $1..."
}

# Fonction pour afficher un message de fin d'opération
end_operation() {
    echo "[INFO] Fin de l'opération : $1."
}

# Fonction pour vérifier la réussite d'une opération
check_success() {
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Opération réussie."
    else
        echo "[ERROR] Échec de l'opération. Vérifiez les messages d'erreur ci-dessus."
        exit 1
    fi
}

# Fonction pour cloner ou mettre à jour un dépôt Git
clone_or_update_repo() {
    local repo_url=$1
    local target_dir=$2

    start_operation "Traitement de $(basename $repo_url)"
    if [ -d "$target_dir/.git" ]; then
        echo "Mise à jour du dépôt $(basename $repo_url)..."
        git -C "$target_dir" pull
    else
        echo "Clonage du dépôt $(basename $repo_url)..."
        git clone $repo_url "$target_dir"
    fi
    check_success
    end_operation "Traitement de $(basename $repo_url)"
}

# Installation de Homebrew
start_operation "Installation de Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    echo "Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    check_success
else
    echo "Homebrew est déjà installé."
fi
end_operation "Installation de Homebrew"

start_operation "Mise à jour de Homebrew"
brew update
end_operation "Mise à jour de Homebrew"

# Installation des dépendances avec Homebrew
echo "Installation des dépendances nécessaires..."
dependencies=("git" "curl" "tree" "htop" "tldr" "jq" "fzf" "httpie" "tmux" "python3")
for app in "${dependencies[@]}"; do
    start_operation "Installation/Verification de ${app}"
    brew install $app
    end_operation "Installation/Verification de ${app}"
done

# Installation de Oh My Zsh
start_operation "Installation de Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installation de Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    check_success
else
    echo "Oh My Zsh est déjà installé."
fi
end_operation "Installation de Oh My Zsh"

# Installation de nvm (Node Version Manager)
start_operation "Installation de nvm (Node Version Manager)"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    check_success
else
    echo "nvm est déjà installé."
fi
end_operation "Installation de nvm"

# Assurez-vous que nvm est chargé pour ce script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Installation de Node.js et Prettier
start_operation "Installation de la dernière version de Node.js via nvm"
nvm install node
nvm use node
end_operation "Installation de Node.js"

# Installation de Prettier
start_operation "Installation de Prettier"
npm install -g prettier
check_success
end_operation "Installation de Prettier"

# Configuration pour zshrc, Vim, et installation des plugins Zsh
start_operation "Configuration de zshrc et Vim"
CONFIG_ZSHRC_URL="https://github.com/YohanGH/Configuration_zshrc"
CONFIG_VIM_URL="https://github.com/YohanGH/Configuration_Vim"
CONFIG_ZSHRC_DIR="$HOME/.config/zsh"
CONFIG_VIM_DIR="$HOME/.vim"

mkdir -p $CONFIG_ZSHRC_DIR
mkdir -p $CONFIG_VIM_DIR

clone_or_update_repo $CONFIG_ZSHRC_URL $CONFIG_ZSHRC_DIR
clone_or_update_repo $CONFIG_VIM_URL $CONFIG_VIM_DIR
end_operation "Configuration de zshrc et Vim"

# Téléchargement et installation de plugins zsh et Powerlevel10k
start_operation "Installation des plugins Zsh et Powerlevel10k"
ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

clone_or_update_repo https://github.com/zsh-users/zsh-autosuggestions $ZSH_AUTOSUGGESTIONS_DIR
clone_or_update_repo https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_SYNTAX_HIGHLIGHTING_DIR
clone_or_update_repo https://github.com/romkatv/powerlevel10k.git $P10K_DIR
end_operation "Installation des plugins Zsh et Powerlevel10k"

# Déplacement des fichiers de configuration
start_operation "Déplacement des fichiers de configuration zshrc et vimrc"
if [ -f "$CONFIG_ZSHRC_DIR/zshrc" ]; then
    cp "$CONFIG_ZSHRC_DIR/zshrc" "$HOME/.zshrc"
    check_success
else
    echo "Le fichier zshrc est introuvable."
fi

if [ -f "$CONFIG_VIM_DIR/.vimrc" ]; then
    cp "$CONFIG_VIM_DIR/.vimrc" "$HOME/.vimrc"
    check_success
else
    echo "Le fichier vimrc est introuvable."
fi
end_operation "Déplacement des fichiers de configuration"

# Création de l'arborescence GTD
start_operation "Création de l'arborescence GTD"
BASE_DIR="$HOME/Documents/GTD"
folders=(
    "1_in-box"
    "activable-non/incubation"
    "activable-non/références/contacts/professionnelle"
    "activable-non/références/contacts/personnel"
    "activable-non/références/database"
    "activable-non/références/documents/textuel"
    "activable-non/références/documents/images"
    "activable-non/références/documents/pdf"
    "activable-non/références/documents/autres"
    "activable-non/références/livres"
    "activable-oui/enattente/professionnel"
    "activable-oui/enattente/personnel"
    "activable-oui/projets/professionnel/devops"
    "activable-oui/projets/professionnel/docker"
    "activable-oui/projets/professionnel/testing"
    "activable-oui/projets/professionnel/github"
    "activable-oui/projets/professionnel/administration"
    "activable-oui/projets/personnel/devops"
    "activable-oui/projets/personnel/docker"
    "activable-oui/projets/personnel/testing"
    "activable-oui/projets/personnel/github"
    "activable-oui/projets/personnel/administration"
    "activable-oui/sous-traitez/en attente"
    "liste-contrôle"
    "idées-réflexions/post-it"
    "archives/note-quotidienne"
    "archives/professionnel"
    "archives/agenda"
    "archives/personnel"
    "template"
)

for folder in "${folders[@]}"; do
    mkdir -p "$BASE_DIR/$folder"
done
end_operation "Création de l'arborescence GTD"

# fonction pour afficher l'arborescence avec `tree`
print_tree() {
    local base_dir=$1
    if command -v tree >/dev/null 2>&1; then
        tree -c "$base_dir"
    else
        echo "la commande 'tree' n'est pas installée, affichage simplifié :"
        find "$base_dir" -print | sed -e 's;[^/]*/;|---;g;s;---|; |;g'
    fi
}

echo "L'arborescence GTD a été créée avec succès dans $BASE_DIR."

echo "----------------------------------------------- /n"
echo "\nConfiguration terminée avec succès."
echo "----------------------------------------------- /n"
