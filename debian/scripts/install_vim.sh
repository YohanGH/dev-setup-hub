#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    install_vim.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/07/22 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Déploie la configuration Vim :
#   - installe vim (si absent)
#   - copie le .vimrc du dépôt
#   - installe vim-plug puis les plugins
#   - DÉSACTIVE Prettier par défaut (pas de formatage automatique)
#
# Usage : ./install_vim.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VIM_SRC="$REPO_DIR/Configuration_Vim"

c_reset='\033[0m'; c_ok='\033[0;32m'; c_info='\033[0;34m'; c_warn='\033[0;33m'
log()  { printf "${c_info}[*]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_ok}[OK]${c_reset} %s\n" "$*"; }
warn() { printf "${c_warn}[!]${c_reset} %s\n" "$*"; }

[ -f "$VIM_SRC/.vimrc" ] || { warn "Introuvable : $VIM_SRC/.vimrc"; exit 1; }

# --- 1. Vim ---------------------------------------------------------------- #
if ! command -v vim >/dev/null 2>&1; then
	log "Installation de vim…"
	sudo apt-get install -y vim
fi

# --- 2. Déploiement du .vimrc --------------------------------------------- #
if [ -e "$HOME/.vimrc" ]; then
	cp -a "$HOME/.vimrc" "$HOME/.vimrc.bak.$(date +%Y%m%d%H%M%S)"
	warn "Ancien ~/.vimrc sauvegardé."
fi
cp "$VIM_SRC/.vimrc" "$HOME/.vimrc"
ok "~/.vimrc déployé."

# --- 3. Désactivation de Prettier par défaut ------------------------------ #
# On injecte un bloc idempotent en fin de fichier : le plugin reste
# installé et disponible via :Prettier, mais aucun formatage automatique.
if ! grep -q "prettier#autoformat" "$HOME/.vimrc"; then
	cat >> "$HOME/.vimrc" <<'VIMEOF'

" --------------------------------------------------------------
" Prettier désactivé par défaut (ajouté par install_vim.sh)
" --------------------------------------------------------------
" Pas de formatage automatique à la sauvegarde.
let g:prettier#autoformat = 0
let g:prettier#autoformat_require_pragma = 0
let g:prettier#exec_cmd_async = 1
" Utilisation manuelle uniquement : :Prettier
VIMEOF
	ok "Prettier désactivé par défaut dans ~/.vimrc."
else
	ok "Prettier déjà configuré comme désactivé."
fi

# --- 4. Fichiers de syntaxe personnalisés --------------------------------- #
if [ -d "$VIM_SRC/syntax" ]; then
	mkdir -p "$HOME/.vim/syntax"
	cp -a "$VIM_SRC/syntax/." "$HOME/.vim/syntax/"
	ok "Fichiers de syntaxe copiés dans ~/.vim/syntax."
fi

# --- 5. vim-plug ----------------------------------------------------------- #
PLUG_FILE="$HOME/.vim/autoload/plug.vim"
if [ -f "$PLUG_FILE" ]; then
	ok "vim-plug déjà présent."
else
	log "Installation de vim-plug…"
	curl -fLo "$PLUG_FILE" --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	ok "vim-plug installé."
fi

mkdir -p "$HOME/.vim/backups" "$HOME/.vim/plugged"

# --- 6. Installation des plugins ------------------------------------------ #
log "Installation des plugins Vim (:PlugInstall)…"
vim -es -u "$HOME/.vimrc" -i NONE -c "PlugInstall --sync" -c "qa" || \
	warn "PlugInstall a rencontré des avertissements — lancez :PlugInstall dans vim si besoin."

ok "Configuration Vim terminée. Header disponible via F1 (:Stdheader)."
