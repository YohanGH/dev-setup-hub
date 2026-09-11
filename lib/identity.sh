#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    identity.sh                                         |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Resolution de l'identite utilisee par les scripts : login, adresse, nom
# affiche. Aucune valeur n'est codee en dur ici.
#
# Cascade, du plus prioritaire au moins :
#
#   1. $HUB_USER / $HUB_MAIL / $HUB_NAME        variables d'environnement
#   2. ~/.config/dev-setup-hub/identity          fichier local, non versionne
#   3. git config user.name / user.email         deja configure sur le poste
#   4. id -un                                    login systeme (pour l'user seul)
#
# Le fichier local est un fragment shell :
#
#   HUB_USER="clogin"
#   HUB_MAIL="prenom.nom@example.org"
#   HUB_NAME="Prenom Nom"
#
# Il n'a pas d'equivalent versionne, et c'est voulu : l'identite change d'un
# poste a l'autre alors que le depot est partage entre les deux.
#
# A sourcer, pas a executer :  . lib/identity.sh
#

[ -n "${_HUB_IDENTITY_SH:-}" ] && return 0
_HUB_IDENTITY_SH=1

_HUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ui.sh
. "$_HUB_LIB_DIR/ui.sh"

IDENTITY_FILE="${IDENTITY_FILE:-$HOME/.config/dev-setup-hub/identity}"

# --------------------------------------------------------------------------- #
#    Chargement du fichier local                                              #
# --------------------------------------------------------------------------- #

# Le fichier est sourc-able mais on ne le source pas : il vient de l'exterieur
# du depot et executer son contenu donnerait plus que ce qu'on demande. On en
# extrait uniquement les trois cles attendues.
identity__lire_fichier() {
	local cle=$1

	[ -r "$IDENTITY_FILE" ] || return 1

	# shellcheck disable=SC1087 -- faux positif : $cle est un scalaire normal,
	# le [[:space:]] qui le suit est une classe POSIX du pattern sed, pas un
	# indice de tableau bash.
	sed -n "s/^[[:space:]]*$cle[[:space:]]*=[[:space:]]*//p" "$IDENTITY_FILE" |
		head -1 |
		sed -e 's/^"//' -e "s/^'//" -e 's/"[[:space:]]*$//' -e "s/'[[:space:]]*$//" |
		grep . || return 1
}

# --------------------------------------------------------------------------- #
#    Resolution                                                               #
# --------------------------------------------------------------------------- #

identity_user() {
	[ -n "${HUB_USER:-}" ] && {
		printf '%s' "$HUB_USER"
		return 0
	}
	identity__lire_fichier HUB_USER && return 0
	git config --get user.name 2>/dev/null | grep . && return 0
	id -un
}

identity_mail() {
	[ -n "${HUB_MAIL:-}" ] && {
		printf '%s' "$HUB_MAIL"
		return 0
	}
	identity__lire_fichier HUB_MAIL && return 0
	git config --get user.email 2>/dev/null | grep . && return 0
	return 1
}

identity_name() {
	[ -n "${HUB_NAME:-}" ] && {
		printf '%s' "$HUB_NAME"
		return 0
	}
	identity__lire_fichier HUB_NAME && return 0
	git config --get user.name 2>/dev/null | grep . && return 0
	identity_user
}

# D'ou vient la valeur : sert a l'afficher plutot qu'a la deviner.
identity_source() {
	local cle=$1

	[ -n "${!cle:-}" ] && {
		printf 'environnement (%s)' "$cle"
		return 0
	}
	identity__lire_fichier "$cle" >/dev/null 2>&1 && {
		# Pas de fs_short ici : cette lib ne depend que de ui.sh.
		case "$IDENTITY_FILE" in
		"$HOME"/*) printf '~%s' "${IDENTITY_FILE#"$HOME"}" ;;
		*) printf '%s' "$IDENTITY_FILE" ;;
		esac
		return 0
	}
	case "$cle" in
	HUB_MAIL) git config --get user.email >/dev/null 2>&1 && printf 'git config user.email' && return 0 ;;
	*) git config --get user.name >/dev/null 2>&1 && printf 'git config user.name' && return 0 ;;
	esac
	printf 'systeme'
}

# --------------------------------------------------------------------------- #
#    Verification                                                             #
# --------------------------------------------------------------------------- #

# Signale les cas ou la valeur trouvee existe mais ne convient pas a l'usage.
# Retourne 1 si l'appelant devrait s'abstenir d'ecrire quoi que ce soit.
identity_verifier_mail() {
	local mail

	if ! mail="$(identity_mail)"; then
		ui_warn 'adresse' 'introuvable — ni HUB_MAIL, ni fichier, ni git config'
		identity_conseil
		return 1
	fi

	# Les adresses de confidentialite GitHub servent a signer des commits,
	# pas a figurer dans un en-tete de fichier.
	case "$mail" in
	*@users.noreply.github.com)
		ui_warn "$mail" 'adresse de confidentialite GitHub, inadaptee a un en-tete'
		identity_conseil
		return 1
		;;
	esac

	return 0
}

identity_conseil() {
	ui_info "Renseigne ton identite une fois pour toutes :"
	ui_info "  mkdir -p $(dirname "$IDENTITY_FILE")"
	ui_info "  printf 'HUB_MAIL=\"toi@example.org\"\\n' >> $IDENTITY_FILE"
}
