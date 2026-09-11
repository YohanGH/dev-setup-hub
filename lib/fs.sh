#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    fs.sh                                               |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Deploiement de fichiers de configuration : liens symboliques, copies et
# sauvegardes. Toutes les fonctions sont idempotentes et ne detruisent
# jamais un fichier existant sans l'archiver d'abord.
#
# Deux modes de deploiement :
#   fs_link  -> lien symbolique vers le depot, modification en direct
#   fs_copy  -> copie, quand l'outil refuse les liens symboliques
#
# A sourcer, pas a executer :  . lib/fs.sh
#

[ -n "${_HUB_FS_SH:-}" ] && return 0
_HUB_FS_SH=1

_HUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ui.sh
. "$_HUB_LIB_DIR/ui.sh"

# --------------------------------------------------------------------------- #
#    Helpers                                                                  #
# --------------------------------------------------------------------------- #

fs_stamp() { date +%Y%m%d-%H%M%S; }

# Raccourcit un chemin pour l'affichage : /Users/x/.zshrc -> ~/.zshrc
fs_short() {
	case "$1" in
	"$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
	*) printf '%s' "$1" ;;
	esac
}

fs_ensure_dir() {
	[ -d "$1" ] && return 0
	mkdir -p "$1" || ui_die "$(fs_short "$1")" 'creation du dossier impossible'
}

# Archive un fichier existant sous <chemin>.bak.<horodatage>.
# Ne fait rien si le chemin est absent ou n'est qu'un lien symbolique :
# un lien n'a pas de contenu propre a preserver.
fs_backup() {
	local cible=$1 sauvegarde

	[ -e "$cible" ] || return 0
	[ -L "$cible" ] && return 0

	sauvegarde="$cible.bak.$(fs_stamp)"
	mv "$cible" "$sauvegarde" ||
		ui_die "$(fs_short "$cible")" 'sauvegarde impossible'
	ui_backup "$(fs_short "$cible")" "sauvegarde -> $(fs_short "$sauvegarde")"
}

# --------------------------------------------------------------------------- #
#    Deploiement                                                              #
# --------------------------------------------------------------------------- #

# fs_link <source-dans-le-depot> <destination>
# Pose un lien symbolique. Le fichier reste editable depuis le depot et les
# modifications sont visibles immediatement, sans reinstallation.
fs_link() {
	local src=$1 dst=$2

	[ -e "$src" ] || {
		ui_err "$(fs_short "$dst")" "source absente : $(fs_short "$src")"
		return 1
	}

	# Deja pointe au bon endroit : rien a faire.
	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		ui_ok "$(fs_short "$dst")" 'lien deja en place'
		return 0
	fi

	fs_ensure_dir "$(dirname "$dst")"
	fs_backup "$dst"

	# -n empeche de creer le lien A L INTERIEUR d'un lien-vers-dossier existant.
	ln -sfn "$src" "$dst" || {
		ui_err "$(fs_short "$dst")" 'creation du lien impossible'
		return 1
	}
	ui_ok "$(fs_short "$dst")" "lien -> $(fs_short "$src")"
}

# fs_copy <source-dans-le-depot> <destination>
# Copie reelle, pour les outils qui reecrivent leur fichier de configuration
# et casseraient un lien symbolique (VSCode et VSCodium, notamment).
fs_copy() {
	local src=$1 dst=$2

	[ -e "$src" ] || {
		ui_err "$(fs_short "$dst")" "source absente : $(fs_short "$src")"
		return 1
	}

	# Contenu identique : on ne touche pas au fichier ni a sa date.
	if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
		ui_ok "$(fs_short "$dst")" 'deja a jour'
		return 0
	fi

	fs_ensure_dir "$(dirname "$dst")"
	fs_backup "$dst"

	cp -R "$src" "$dst" || {
		ui_err "$(fs_short "$dst")" 'copie impossible'
		return 1
	}
	ui_ok "$(fs_short "$dst")" 'copie'
}

# fs_append_once <fichier> <marqueur> <ligne>...
# Ajoute des lignes a un fichier seulement si le marqueur n'y est pas deja.
# Evite d'empiler dix fois le meme bloc dans ~/.zshrc a chaque execution.
fs_append_once() {
	local fichier=$1 marqueur=$2
	shift 2

	if [ -f "$fichier" ] && grep -qF "$marqueur" "$fichier"; then
		ui_ok "$(fs_short "$fichier")" 'bloc deja present'
		return 0
	fi

	fs_ensure_dir "$(dirname "$fichier")"
	printf '\n' >>"$fichier"
	printf '%s\n' "$@" >>"$fichier"
	ui_ok "$(fs_short "$fichier")" 'bloc ajoute'
}
