#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    profile.sh                                          |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Lecture des listes de paquets de profiles/.
#
# Format d'une liste :
#   - un paquet par ligne
#   - '#' commente jusqu'a la fin de la ligne
#   - une ligne vide est ignoree
#   - '!' en prefixe marque un paquet optionnel : son absence des depots
#     n'est pas une erreur
#
# A sourcer, pas a executer :  . lib/profile.sh
#

[ -n "${_HUB_PROFILE_SH:-}" ] && return 0
_HUB_PROFILE_SH=1

_HUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/os.sh
. "$_HUB_LIB_DIR/os.sh"

# Racine du depot, deduite de l'emplacement de cette lib.
HUB_ROOT="${HUB_ROOT:-$(dirname "$_HUB_LIB_DIR")}"

# --------------------------------------------------------------------------- #
#    Lecture                                                                  #
# --------------------------------------------------------------------------- #

# Retire commentaires, espaces et lignes vides. Un fichier absent donne une
# liste vide : tous les profils ne sont pas peuples sur tous les OS.
profile__clean() {
	[ -f "$1" ] || return 0
	sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" |
		grep -v '^$'
}

# Paquets obligatoires : les lignes sans prefixe '!'.
profile_required() {
	profile__clean "$1" | grep -v '^!' || true
}

# Paquets optionnels : les lignes prefixees '!', prefixe retire.
profile_optional() {
	profile__clean "$1" | grep '^!' | sed 's/^!//' || true
}

# Chemin d'une liste : profile_path common -> <depot>/profiles/common.list
profile_path() {
	printf '%s/profiles/%s.list' "$HUB_ROOT" "$1"
}

# --------------------------------------------------------------------------- #
#    Installation                                                             #
# --------------------------------------------------------------------------- #

# profile_install <nom-de-profil>
# Installe les paquets obligatoires puis les optionnels de la liste. Le nom
# est celui du fichier sans extension : common, macos, debian.
profile_install() {
	local nom=$1 fichier
	fichier="$(profile_path "$nom")"

	if [ ! -f "$fichier" ]; then
		ui_skip "$nom.list" 'profil absent, ignore'
		return 0
	fi

	local requis optionnels
	# mapfile n'existe pas partout ; on passe par une chaine decoupee par $IFS.
	requis="$(profile_required "$fichier" | tr '\n' ' ')"
	optionnels="$(profile_optional "$fichier" | tr '\n' ' ')"

	# shellcheck disable=SC2086
	[ -n "${requis// /}" ] && pkg_install $requis
	# shellcheck disable=SC2086
	[ -n "${optionnels// /}" ] && pkg_install_optional $optionnels

	return 0
}

# profile_install_cask <nom-de-profil>
# Variante macOS pour les applications graphiques. Sans effet ailleurs.
profile_install_cask() {
	local nom=$1 fichier pkg

	[ "$(os_id)" = macos ] || return 0

	fichier="$(profile_path "$nom")"
	[ -f "$fichier" ] || return 0

	pkg_require

	while read -r pkg; do
		[ -n "$pkg" ] || continue
		if brew list --cask --versions "$pkg" >/dev/null 2>&1; then
			ui_ok "$pkg" 'deja present'
		elif brew install --cask "$pkg" >/dev/null 2>&1; then
			ui_ok "$pkg" 'installe'
		else
			ui_warn "$pkg" 'echec de l installation'
		fi
	done < <(profile_required "$fichier")

	while read -r pkg; do
		[ -n "$pkg" ] || continue
		if brew list --cask --versions "$pkg" >/dev/null 2>&1; then
			ui_ok "$pkg" 'deja present'
		elif brew install --cask "$pkg" >/dev/null 2>&1; then
			ui_ok "$pkg" 'installe'
		else
			ui_skip "$pkg" 'indisponible, ignore (optionnel)'
		fi
	done < <(profile_optional "$fichier")
}
