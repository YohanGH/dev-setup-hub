#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    10-shell.sh                                         |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Shell — zsh, oh-my-zsh, powerlevel10k
#
# Etape 2 : shell zsh — oh-my-zsh, powerlevel10k, plugins, et deploiement de
# config/zsh/.
#
# Le zshrc est pose en LIEN SYMBOLIQUE : editer config/zsh/zshrc dans le depot
# suffit, aucune reinstallation n'est necessaire.
#
# Lancable seul :  ./install/10-shell.sh
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

ZSH_SRC="$HUB_ROOT/config/zsh"

ui_section "${HUB_STEP:-2/5}" 'Shell — zsh'

os_refuse_root
os_require

has_cmd zsh || ui_die 'zsh' 'zsh absent, lance install/00-packages.sh d abord'

# --- 1. oh-my-zsh ---------------------------------------------------------- #
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

if [ -d "$ZSH" ]; then
	ui_ok 'oh-my-zsh' 'deja present'
else
	ui_run 'oh-my-zsh' 'installation...'
	# KEEP_ZSHRC empeche l'installeur d'ecraser le zshrc qu'on va lier ;
	# CHSH et RUNZSH le gardent non interactif.
	if RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
		"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
		>/dev/null 2>&1; then
		ui_ok 'oh-my-zsh' 'installe'
	else
		ui_die 'oh-my-zsh' 'echec de l installation'
	fi
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# --- 2. powerlevel10k et plugins ------------------------------------------- #
# Le zshrc declare ZSH_THEME="powerlevel10k/powerlevel10k" et charge les
# plugins zsh-autosuggestions et zsh-syntax-highlighting : sans eux le shell
# demarre en erreur.
clone_depot() {
	local nom=$1 url=$2 dest=$3

	if [ -d "$dest/.git" ]; then
		ui_ok "$nom" 'deja present'
		return 0
	fi

	ui_run "$nom" 'clonage...'
	if git clone --depth=1 "$url" "$dest" >/dev/null 2>&1; then
		ui_ok "$nom" 'installe'
	else
		ui_warn "$nom" 'echec du clonage'
	fi
}

clone_depot powerlevel10k \
	https://github.com/romkatv/powerlevel10k.git \
	"$ZSH_CUSTOM/themes/powerlevel10k"

clone_depot zsh-autosuggestions \
	https://github.com/zsh-users/zsh-autosuggestions \
	"$ZSH_CUSTOM/plugins/zsh-autosuggestions"

clone_depot zsh-syntax-highlighting \
	https://github.com/zsh-users/zsh-syntax-highlighting \
	"$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# --- 3. Deploiement de la configuration ------------------------------------ #
# Liens et non copies : editer config/zsh/ dans le depot suffit, la
# modification est active au prochain shell sans repasser par l'installeur.
# Les deux fichiers sont charges par le zshrc versionne, qui ne connait que
# leurs noms cibles.
fs_link "$ZSH_SRC/zshrc" "$HOME/.zshrc"
fs_link "$ZSH_SRC/my-alias-v2.zsh" "$HOME/.zsh_aliases"

# ~/.zsh_local n'est pas versionne : il recoit ce qui varie d'un poste a
# l'autre. ~/.local/bin y entre car il porte le lien fd cree sous Debian par
# 00-packages.sh.
fs_append_once "$HOME/.zsh_local" 'HOME/.local/bin' \
	'# Reglages propres a cette machine. Charge par ~/.zshrc.' \
	'export PATH="$HOME/.local/bin:$PATH"'

# --- 4. Shell par defaut ---------------------------------------------------- #
# chsh demande le mot de passe et modifie un reglage systeme : on ne le fait
# pas a la place de l'utilisateur, on lui donne la commande.
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
	ui_warn 'shell' 'zsh n est pas ton shell par defaut'
	ui_info "  chsh -s \"\$(command -v zsh)\""
fi

ui_blank
