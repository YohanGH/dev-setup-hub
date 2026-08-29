#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    50-external.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Depots externes — claude-config, halo
#
# Etape : recuperation des depots declares dans external.conf.
#
# Ces projets vivent dans leurs propres depots GitHub. Les copier ici les
# ferait deriver de l'amont, donc on les clone a l'installation.
#
#   ./install/50-external.sh                # entrees 'on' seulement
#   ./install/50-external.sh --with halo    # + une entree 'off'
#   ./install/50-external.sh --all          # tout, y compris les 'off'
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

MANIFESTE="$HUB_ROOT/external.conf"
DEMANDES=''
TOUT=0

while [ $# -gt 0 ]; do
	case "$1" in
	--with)
		shift
		[ $# -gt 0 ] || ui_die '--with' 'nom de depot attendu'
		DEMANDES="$DEMANDES $1"
		;;
	--all) TOUT=1 ;;
	*) ui_die "$1" 'option inconnue' ;;
	esac
	shift
done

ui_section "${HUB_STEP:-6/7}" 'Depots externes'

[ -f "$MANIFESTE" ] || ui_die 'external.conf' 'manifeste introuvable'
has_cmd git || ui_die 'git' 'git est requis pour recuperer les depots'

# La plateforme du manifeste est plus large que os_id : debian et toute autre
# distribution y sont 'linux'.
plateforme_courante() {
	case "$(os_id)" in
	macos) printf 'macos' ;;
	*) printf 'linux' ;;
	esac
}

demande() {
	case " $DEMANDES " in
	*" $1 "*) return 0 ;;
	*) return 1 ;;
	esac
}

# --------------------------------------------------------------------------- #
#    Recuperation                                                             #
# --------------------------------------------------------------------------- #

recuperer() {
	local nom=$1 url=$2 dest=$3 build=$4

	if [ -d "$dest/.git" ]; then
		ui_run "$nom" 'mise a jour...'
		if git -C "$dest" pull --ff-only >/dev/null 2>&1; then
			ui_ok "$nom" "a jour ($(fs_short "$dest"))"
		else
			# Un pull non fast-forward veut dire modifications locales ou
			# historique divergent : on ne touche a rien.
			ui_warn "$nom" 'mise a jour impossible, depot laisse tel quel'
			return 0
		fi
	else
		ui_run "$nom" 'clonage...'
		fs_ensure_dir "$(dirname "$dest")"
		if git clone --depth=1 "$url" "$dest" >/dev/null 2>&1; then
			ui_ok "$nom" "clone -> $(fs_short "$dest")"
		else
			ui_err "$nom" 'echec du clonage'
			return 1
		fi
	fi

	[ -n "$build" ] || return 0

	# La construction n'est tentee que si son outil est present : on ne va pas
	# installer un toolchain Rust dans le dos de l'utilisateur.
	local outil=${build%% *}
	if ! has_cmd "$outil"; then
		ui_skip "$nom" "$outil absent, construction ignoree"
		ui_info "Installe le toolchain puis relance : cd $(fs_short "$dest") && $build"
		return 0
	fi

	ui_run "$nom" "construction ($build)..."
	if (cd "$dest" && eval "$build") >/dev/null 2>&1; then
		ui_ok "$nom" 'construit'
	else
		ui_warn "$nom" 'echec de la construction'
	fi
}

# --------------------------------------------------------------------------- #
#    Lecture du manifeste                                                     #
# --------------------------------------------------------------------------- #

courante="$(plateforme_courante)"
traites=0

while IFS='|' read -r nom url dest plateforme defaut build; do
	# Nettoyage des espaces de mise en forme du manifeste.
	nom="$(printf '%s' "$nom" | tr -d '[:space:]')"
	url="$(printf '%s' "$url" | tr -d '[:space:]')"
	dest="$(printf '%s' "$dest" | tr -d '[:space:]')"
	plateforme="$(printf '%s' "$plateforme" | tr -d '[:space:]')"
	defaut="$(printf '%s' "$defaut" | tr -d '[:space:]')"
	build="$(printf '%s' "${build:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

	# Commentaires et lignes vides.
	case "$nom" in '' | '#'*) continue ;; esac

	if [ "$plateforme" != all ] && [ "$plateforme" != "$courante" ]; then
		ui_skip "$nom" "reserve a $plateforme, poste en $courante"
		continue
	fi

	if [ "$defaut" != on ] && [ "$TOUT" -eq 0 ] && ! demande "$nom"; then
		ui_skip "$nom" "desactive par defaut (--with $nom pour l activer)"
		continue
	fi

	recuperer "$nom" "$url" "${dest/#\~/$HOME}" "$build" || true
	traites=$((traites + 1))
done <"$MANIFESTE"

[ "$traites" -gt 0 ] || ui_info 'Aucun depot a recuperer sur cette plateforme.'

ui_blank
