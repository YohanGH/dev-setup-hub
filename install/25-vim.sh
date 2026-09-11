#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    25-vim.sh                                           |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/09/11 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Vim — configuration, syntaxes et plugins
#
# Etape : deploie la configuration Vim du depot.
#
# Jusqu'ici aucune etape ne le faisait. Seul debian/scripts/install_vim.sh
# deployait un .vimrc, depuis sa propre copie — d'ou l'impression que
# ./install.sh ne posait que « la config de base » : il ne posait rien du tout.
#
# ~/.vimrc est un LIEN vers vim/.vimrc. Vim ne reecrit jamais son fichier de
# configuration, editer le depot suffit — meme raisonnement que ~/.zshrc,
# voir la note « Lien ou copie ? » de CLAUDE.md.
#
#   ./install/25-vim.sh
#   ./install/25-vim.sh --no-plugins   # sans PlugInstall
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

SRC="$HUB_ROOT/vim"
VIMRC="$SRC/.vimrc"
BUILDER="$SRC/vim-builder.sh"
PLUG_URL='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
AVEC_PLUGINS=1

[ "${1:-}" = '--no-plugins' ] && AVEC_PLUGINS=0

ui_section "${HUB_STEP:-4/9}" 'Vim — configuration'

[ -f "$VIMRC" ] || ui_die '.vimrc' 'introuvable dans vim/'

has_cmd vim || ui_warn 'vim' 'absent — la config est posee, installe-le ensuite'

# --------------------------------------------------------------------------- #
#    Le decoupage en fragments est-il termine ?                               #
# --------------------------------------------------------------------------- #
#
# Contrat de vim-builder.sh : .vimrc n'est qu'un chargeur, toute la
# configuration vit dans les fragments qu'il source. Tant que .vimrc contient
# encore ses propres reglages, les lancer TOUS LES DEUX chargerait la moitie
# de la config en double — d'abord la version monolithique, puis la version
# extraite. On mesure donc ce qu'il reste avant de decider.

MARQUE_DEBUT='" >>> vim-builder >>>'
MARQUE_FIN='" <<< vim-builder <<<'

# Lignes de configuration reelles hors bloc genere : ni vides, ni commentaires.
lignes_hors_bloc() {
	awk -v b="$MARQUE_DEBUT" -v e="$MARQUE_FIN" '
		$0 == b            { dans = 1; next }
		$0 == e            { dans = 0; next }
		dans               { next }
		/^[[:space:]]*$/   { next }
		/^[[:space:]]*"/   { next }
		{ n++ }
		END { print n + 0 }
	' "$VIMRC"
}

RESTANTES="$(lignes_hors_bloc)"

if [ "$RESTANTES" -eq 0 ] && [ -x "$BUILDER" ]; then
	# .vimrc ne contient plus que le bloc genere : le builder peut travailler.
	if SORTIE="$(bash "$BUILDER" 2>&1)"; then
		# Sa sortie a son propre format ; on la reindente pour ne pas casser
		# l'alignement de lib/ui.sh.
		while IFS= read -r ligne; do
			if [ -n "$ligne" ]; then ui_info "  $ligne"; fi
		done <<<"$SORTIE"
		ui_ok '.vimrc' 'genere depuis les fragments'
	else
		ui_err 'vim-builder.sh' 'echec de la generation'
	fi
else
	# Cas actuel. On deploie quand meme le .vimrc tel qu'il est : mieux vaut
	# une config monolithique qui marche que pas de config du tout.
	fs_link "$VIMRC" "$HOME/.vimrc"
	ui_skip 'vim-builder' "$RESTANTES lignes encore dans .vimrc, fragments non charges"
	ui_info '  Le decoupage en fragments n est pas termine : les charger en plus'
	ui_info '  du .vimrc actuel doublerait la configuration. Cette etape lancera'
	ui_info '  vim-builder.sh d elle-meme quand .vimrc ne sera plus qu un chargeur.'
fi

# --------------------------------------------------------------------------- #
#    Syntaxes                                                                 #
# --------------------------------------------------------------------------- #
# Fichiers maison : vim ne sait pas les retrouver seul, et ne les reecrit pas.

if [ -d "$SRC/syntax" ]; then
	for f in "$SRC"/syntax/*.vim; do
		[ -f "$f" ] || continue
		fs_link "$f" "$HOME/.vim/syntax/$(basename "$f")"
	done
fi

# --------------------------------------------------------------------------- #
#    vim-plug                                                                 #
# --------------------------------------------------------------------------- #
#
# Installe ici plutot que laisse au curl de secours de .vim.plugins : celui-ci
# se declenche au demarrage de vim, sans rien dire de ce qu'il fait, et un
# echec reseau y passe inapercu.

fs_ensure_dir "$HOME/.vim/backups" # attendu par 'set backupdir' du .vimrc
fs_ensure_dir "$HOME/.vim/plugged"

PLUG="$HOME/.vim/autoload/plug.vim"

if [ -f "$PLUG" ]; then
	ui_ok 'vim-plug' 'deja present'
elif ! has_cmd curl; then
	ui_warn 'vim-plug' 'curl absent, installation impossible'
else
	ui_run 'vim-plug' 'telechargement...'
	fs_ensure_dir "$(dirname "$PLUG")"
	if curl -fsSL -o "$PLUG" "$PLUG_URL"; then
		ui_ok 'vim-plug' 'installe'
	else
		ui_warn 'vim-plug' 'telechargement en echec'
	fi
fi

# --------------------------------------------------------------------------- #
#    Plugins                                                                  #
# --------------------------------------------------------------------------- #

if [ "$AVEC_PLUGINS" -ne 1 ]; then
	ui_skip 'plugins' '--no-plugins'
elif ! has_cmd vim || [ ! -f "$PLUG" ]; then
	ui_skip 'plugins' 'vim ou vim-plug absent'
	ui_info '  Lance :PlugInstall dans vim une fois les deux en place.'
else
	ui_run 'plugins' 'PlugInstall...'
	# -es : mode ex silencieux. -i NONE : pas de viminfo. stdin ferme pour
	# qu'une eventuelle invite ne bloque pas une installation non surveillee.
	if vim -es -u "$HOME/.vimrc" -i NONE \
		-c 'PlugInstall --sync' -c 'qa' </dev/null >/dev/null 2>&1; then
		ui_ok 'plugins' 'installes'
	else
		ui_warn 'plugins' 'PlugInstall en echec, relance :PlugInstall dans vim'
	fi
fi

ui_blank
