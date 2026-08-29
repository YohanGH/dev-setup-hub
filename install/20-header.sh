#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    20-header.sh                                        |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Header 42 — plugin Vim stdheader
#
# Etape 3 : header 42 automatique dans Vim.
#
# Remplace debian/scripts/set_header.sh, en deployant depuis la copie unique
# config/header/ au lieu d'une variante propre a Debian.
#
# Lancable seul :  ./install/20-header.sh
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/identity.sh
. "$HUB_ROOT/lib/identity.sh"

HEADER_SRC="$HUB_ROOT/config/header/plugin/stdheader.vim"

ui_section "${HUB_STEP:-3/6}" 'Header 42 — plugin Vim'

[ -f "$HEADER_SRC" ] || ui_die 'stdheader.vim' 'introuvable dans config/header/'

# --- Plugin ----------------------------------------------------------------- #
# Lien et non copie : corriger le header dans le depot suffit.
fs_link "$HEADER_SRC" "$HOME/.vim/plugin/stdheader.vim"

# --- Identite --------------------------------------------------------------- #
# Le plugin lit USER et MAIL pour remplir l'en-tete. Rien n'est code en dur :
# lib/identity.sh resout les valeurs, et elles atterrissent dans ~/.zsh_local,
# non versionne — l'identite est propre au poste, le zshrc est partage.
if identity_verifier_mail; then
	fs_append_once "$HOME/.zsh_local" 'export MAIL=' \
		'# Identite utilisee par le header 42 (plugin stdheader.vim).' \
		"export USER=\"$(identity_user)\"" \
		"export MAIL=\"$(identity_mail)\""
	ui_ok 'identite' "$(identity_user) <$(identity_mail)>"
	ui_info "source : $(identity_source HUB_MAIL)"
else
	# Sans adresse exploitable on n'ecrit rien plutot que d'inventer un
	# domaine : le plugin fonctionne, l'en-tete affichera une valeur vide.
	ui_skip 'identite' 'non ecrite — adresse a renseigner'
fi

ui_info 'Ouvre un fichier dans vim puis F1 (ou :Stdheader) pour inserer l en-tete.'
ui_blank
