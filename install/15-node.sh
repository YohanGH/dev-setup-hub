#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    15-node.sh                                          |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Node — nvm, Node LTS, prettier
#
# Etape : chaine Node via nvm.
#
# Reprend ce que faisait setup/setup-configs.sh sur macOS, et l'etend a Debian.
# nvm n'est volontairement pas installe par le gestionnaire de paquets : il se
# gere lui-meme et doit rester dans $HOME pour que les versions de Node
# s'installent sans sudo.
#
# Lancable seul :  ./install/15-node.sh
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_VERSION=v0.40.1

ui_section "${HUB_STEP:-4/7}" 'Node — nvm'

os_refuse_root

# --- 1. nvm ----------------------------------------------------------------- #
if [ -s "$NVM_DIR/nvm.sh" ]; then
	ui_ok 'nvm' 'deja present'
else
	ui_run 'nvm' 'installation...'
	if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" |
		PROFILE=/dev/null bash >/dev/null 2>&1; then
		ui_ok 'nvm' "installe ($NVM_VERSION)"
	else
		ui_err 'nvm' 'echec de l installation'
		exit 1
	fi
fi

# PROFILE=/dev/null empeche l'installeur de modifier ~/.zshrc, qui est un lien
# vers le depot. C'est donc a nous de declarer nvm, dans le fichier local.
fs_append_once "$HOME/.zsh_local" 'NVM_DIR' \
	'# Node Version Manager, installe par install/15-node.sh.' \
	'export NVM_DIR="$HOME/.nvm"' \
	'[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
	'[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'

# --- 2. Node ---------------------------------------------------------------- #
# nvm est une fonction shell, pas un binaire : il faut le sourcer ici.
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

if nvm ls --no-colors 2>/dev/null | grep -q 'lts'; then
	ui_ok 'node' "deja present ($(node --version 2>/dev/null || echo '?'))"
else
	ui_run 'node' 'installation de la version LTS...'
	if nvm install --lts >/dev/null 2>&1 && nvm alias default 'lts/*' >/dev/null 2>&1; then
		ui_ok 'node' "installe ($(node --version 2>/dev/null || echo '?'))"
	else
		ui_warn 'node' 'echec de l installation'
	fi
fi

# --- 3. Prettier ------------------------------------------------------------ #
if has_cmd prettier; then
	ui_ok 'prettier' 'deja present'
elif has_cmd npm; then
	ui_run 'prettier' 'installation...'
	if npm install -g prettier >/dev/null 2>&1; then
		ui_ok 'prettier' 'installe'
	else
		ui_warn 'prettier' 'echec de l installation'
	fi
else
	ui_skip 'prettier' 'npm indisponible'
fi

ui_blank
