#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    os.sh                                               |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Couche d'abstraction systeme : c'est le SEUL endroit du depot qui sait
# distinguer macOS de Debian. Les scripts de install/ appellent pkg_install
# et n'ont jamais a tester l'OS eux-memes.
#
# A sourcer, pas a executer :  . lib/os.sh
#

[ -n "${_HUB_OS_SH:-}" ] && return 0
_HUB_OS_SH=1

_HUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ui.sh
. "$_HUB_LIB_DIR/ui.sh"

# --------------------------------------------------------------------------- #
#    Detection                                                                #
# --------------------------------------------------------------------------- #

# macos | debian | unsupported
# Le resultat est mis en cache : la detection lit des fichiers, inutile de
# recommencer a chaque appel.
os_id() {
	if [ -n "${_HUB_OS_ID:-}" ]; then
		printf '%s' "$_HUB_OS_ID"
		return 0
	fi

	local id=unsupported

	case "$(uname -s)" in
	Darwin)
		id=macos
		;;
	Linux)
		if [ -r /etc/os-release ]; then
			# ID et ID_LIKE viennent de /etc/os-release ; ubuntu, mint et
			# consorts declarent ID_LIKE=debian.
			local ID='' ID_LIKE=''
			# shellcheck disable=SC1091
			. /etc/os-release
			case "$ID $ID_LIKE" in
			*debian* | *ubuntu*) id=debian ;;
			esac
		fi
		;;
	esac

	_HUB_OS_ID=$id
	printf '%s' "$id"
}

os_arch() { uname -m; }

# "macOS 14.6 - arm64" / "Ubuntu 22.04 - x86_64"
os_label() {
	local nom version

	case "$(os_id)" in
	macos)
		nom=macOS
		version="$(sw_vers -productVersion 2>/dev/null || printf '?')"
		;;
	debian)
		local NAME='' VERSION_ID=''
		# shellcheck disable=SC1091
		[ -r /etc/os-release ] && . /etc/os-release
		nom="${NAME:-Debian}"
		version="${VERSION_ID:-?}"
		;;
	*)
		nom="$(uname -s)"
		version="$(uname -r)"
		;;
	esac

	printf '%s %s - %s' "$nom" "$version" "$(os_arch)"
}

# Interrompt si l'OS n'est pas gere.
os_require() {
	[ "$(os_id)" = unsupported ] &&
		ui_die "$(uname -s)" 'OS non gere : ce depot cible macOS et Debian/Ubuntu'
	return 0
}

# Refuse de tourner en root : brew le rejette, et apt n'a besoin que de sudo
# ponctuellement. Les fichiers deployes doivent appartenir a l'utilisateur.
os_refuse_root() {
	[ "$(id -u)" -eq 0 ] &&
		ui_die 'root' "ne lance pas ce script en root, sudo sera demande au besoin"
	return 0
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------------------- #
#    Paquets                                                                  #
# --------------------------------------------------------------------------- #

# brew | apt
pkg_manager() {
	case "$(os_id)" in
	macos) printf 'brew' ;;
	debian) printf 'apt' ;;
	*) printf '' ;;
	esac
}

# Verifie que le gestionnaire est utilisable avant toute installation.
pkg_require() {
	case "$(pkg_manager)" in
	brew)
		has_cmd brew ||
			ui_die 'brew' 'Homebrew absent, installe-le : https://brew.sh'
		;;
	apt)
		has_cmd apt-get ||
			ui_die 'apt-get' 'apt-get introuvable sur ce systeme Debian'
		;;
	*)
		os_require
		;;
	esac
}

# Rafraichit l'index des paquets. Idempotent, silencieux si deja fait
# dans la meme execution.
pkg_refresh() {
	[ -n "${_HUB_PKG_REFRESHED:-}" ] && return 0
	_HUB_PKG_REFRESHED=1

	case "$(pkg_manager)" in
	brew) brew update >/dev/null 2>&1 || ui_warn 'brew update' 'echec, on continue' ;;
	apt) sudo apt-get update -qq || ui_warn 'apt update' 'echec, on continue' ;;
	esac
}

# Un paquet est-il deja installe ?
pkg_installed() {
	case "$(pkg_manager)" in
	brew) brew list --formula --versions "$1" >/dev/null 2>&1 ;;
	apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed' ;;
	*) return 1 ;;
	esac
}

# pkg_install <paquet>...
# Installe ce qui manque, saute le reste. Une ligne d'UI par paquet.
pkg_install() {
	local pkg

	pkg_require

	for pkg in "$@"; do
		if pkg_installed "$pkg"; then
			ui_ok "$pkg" 'deja present'
			continue
		fi

		ui_run "$pkg" 'installation...'

		case "$(pkg_manager)" in
		brew)
			if brew install "$pkg" >/dev/null 2>&1; then
				ui_ok "$pkg" 'installe'
			else
				ui_warn "$pkg" 'echec de l installation'
			fi
			;;
		apt)
			if sudo apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
				ui_ok "$pkg" 'installe'
			else
				ui_warn "$pkg" 'echec de l installation'
			fi
			;;
		esac
	done
}

# pkg_install_optional <paquet>...
# Meme chose, mais un echec est signale comme "ignore" et jamais comme un
# probleme : sert aux paquets absents de certains depots (thefuck, autojump).
pkg_install_optional() {
	local pkg

	pkg_require

	for pkg in "$@"; do
		if pkg_installed "$pkg"; then
			ui_ok "$pkg" 'deja present'
			continue
		fi

		case "$(pkg_manager)" in
		brew) brew install "$pkg" >/dev/null 2>&1 ;;
		apt) sudo apt-get install -y -qq "$pkg" >/dev/null 2>&1 ;;
		esac

		if pkg_installed "$pkg"; then
			ui_ok "$pkg" 'installe'
		else
			ui_skip "$pkg" 'indisponible, ignore (optionnel)'
		fi
	done
}

# --------------------------------------------------------------------------- #
#    Sudo                                                                     #
# --------------------------------------------------------------------------- #

# Demande le mot de passe une fois, au debut, plutot qu'au milieu d'une
# installation longue. Sans effet sur macOS ou brew n'en a pas besoin.
os_warm_sudo() {
	[ "$(pkg_manager)" = apt ] || return 0
	has_cmd sudo || ui_die 'sudo' 'sudo est requis pour installer des paquets'

	sudo -n true 2>/dev/null && return 0

	ui_info 'Droits administrateur requis pour installer les paquets.'
	sudo -v || ui_die 'sudo' 'authentification refusee'
}
