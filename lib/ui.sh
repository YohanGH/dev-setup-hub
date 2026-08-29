#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    ui.sh                                               |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Primitives d'affichage terminal partagees par tous les scripts d'installation.
# A sourcer, pas a executer :  . lib/ui.sh
#
# Rendu vise :
#
#   +--------------------------------------------------------------+
#   |  DEV-SETUP-HUB                              macOS - arm64    |
#   +--------------------------------------------------------------+
#
#     > 1/7  Paquets systeme
#     --------------------------------------------------------------
#         v  git            deja present
#         v  htop           installe
#         -  thefuck        ignore (optionnel)
#
# Degradation : couleurs desactivees si NO_COLOR est defini, si la sortie
# n'est pas un terminal ou si TERM vaut dumb. Glyphes ASCII si la locale
# n'est pas UTF-8. Le rendu reste lisible dans un fichier de log.
#

# Garde anti-double-source : les libs se sourcent entre elles.
[ -n "${_HUB_UI_SH:-}" ] && return 0
_HUB_UI_SH=1

# Largeur du cadre, ajustable depuis l'appelant.
UI_WIDTH="${UI_WIDTH:-64}"

# Repond automatiquement oui a ui_confirm (mode --yes).
UI_ASSUME_YES="${UI_ASSUME_YES:-0}"

# --------------------------------------------------------------------------- #
#    Detection des capacites du terminal                                      #
# --------------------------------------------------------------------------- #

ui__has_color() {
	[ -z "${NO_COLOR:-}" ] && [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]
}

ui__has_unicode() {
	case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
	*UTF-8* | *utf-8* | *UTF8* | *utf8*) return 0 ;;
	*) return 1 ;;
	esac
}

if ui__has_color; then
	UI_C_RESET=$'\033[0m'
	UI_C_DIM=$'\033[2m'
	UI_C_BOLD=$'\033[1m'
	UI_C_OK=$'\033[0;32m'
	UI_C_WARN=$'\033[0;33m'
	UI_C_ERR=$'\033[0;31m'
	UI_C_INFO=$'\033[0;34m'
else
	UI_C_RESET='' UI_C_DIM='' UI_C_BOLD=''
	UI_C_OK='' UI_C_WARN='' UI_C_ERR='' UI_C_INFO=''
fi

if ui__has_unicode; then
	UI_G_OK='✔' UI_G_WARN='▲' UI_G_ERR='✖' UI_G_SKIP='⊘'
	UI_G_RUN='↓' UI_G_BAK='↩' UI_G_ARROW='▸'
	UI_B_TL='╭' UI_B_TR='╮' UI_B_BL='╰' UI_B_BR='╯'
	UI_B_H='─' UI_B_V='│' UI_B_SEP='─'
else
	UI_G_OK='+' UI_G_WARN='!' UI_G_ERR='x' UI_G_SKIP='-'
	UI_G_RUN='~' UI_G_BAK='<' UI_G_ARROW='>'
	UI_B_TL='+' UI_B_TR='+' UI_B_BL='+' UI_B_BR='+'
	UI_B_H='-' UI_B_V='|' UI_B_SEP='-'
fi

# --------------------------------------------------------------------------- #
#    Helpers internes                                                         #
# --------------------------------------------------------------------------- #

# Repete un motif N fois. Sert aux bordures.
ui__repeat() {
	local motif=$1 n=$2 out=''
	while [ "$n" -gt 0 ]; do
		out="$out$motif"
		n=$((n - 1))
	done
	printf '%s' "$out"
}

# Pade a droite en comptant les CARACTERES et non les octets : printf '%-Ns'
# pade en octets, un accent dans le libelle casserait donc l'alignement.
#
# Un libelle plus long que la colonne la deborde — c'est inevitable — mais on
# garantit toujours une espace de separation pour ne pas coller au texte suivant.
ui__pad() {
	local text=$1 width=$2 len=${#1}

	printf '%s' "$text"

	if [ "$len" -ge "$width" ]; then
		printf ' '
		return 0
	fi

	while [ "$len" -lt "$width" ]; do
		printf ' '
		len=$((len + 1))
	done
}

# Ligne de statut : indentation, glyphe colore, libelle cadre, texte libre.
# Le texte libre est en dernier, donc sa largeur n'influe sur aucun alignement.
ui__line() {
	local color=$1 glyph=$2 label=$3 text=${4:-}
	printf '    %s%s%s  ' "$color" "$glyph" "$UI_C_RESET"
	ui__pad "$label" 16
	if [ -n "$text" ]; then
		printf '%s%s%s' "$UI_C_DIM" "$text" "$UI_C_RESET"
	fi
	printf '\n'
}

# --------------------------------------------------------------------------- #
#    API publique                                                             #
# --------------------------------------------------------------------------- #

# ui_banner "DEV-SETUP-HUB" "macOS - arm64"
ui_banner() {
	local titre=$1 droite=${2:-}
	local inner=$((UI_WIDTH - 2))
	local reste=$((inner - 2 - ${#titre} - ${#droite} - 2))

	[ "$reste" -lt 1 ] && reste=1

	printf '\n%s' "$UI_C_INFO"
	printf '%s%s%s\n' "$UI_B_TL" "$(ui__repeat "$UI_B_H" "$inner")" "$UI_B_TR"
	printf '%s  %s%s%s' "$UI_B_V" "$UI_C_BOLD" "$titre" "$UI_C_RESET$UI_C_INFO"
	printf '%s%s  %s\n' "$(ui__repeat ' ' "$reste")" "$droite" "$UI_B_V"
	printf '%s%s%s\n' "$UI_B_BL" "$(ui__repeat "$UI_B_H" "$inner")" "$UI_B_BR"
	printf '%s\n' "$UI_C_RESET"
}

# ui_section "1/7" "Paquets systeme"
ui_section() {
	local etape=$1 titre=$2
	printf '  %s%s %s%s  %s%s\n' \
		"$UI_C_INFO" "$UI_G_ARROW" "$UI_C_BOLD" "$etape" "$titre" "$UI_C_RESET"
	printf '  %s%s%s\n' \
		"$UI_C_DIM" "$(ui__repeat "$UI_B_SEP" $((UI_WIDTH - 2)))" "$UI_C_RESET"
}

ui_ok() { ui__line "$UI_C_OK" "$UI_G_OK" "$1" "${2:-}"; }
ui_warn() { ui__line "$UI_C_WARN" "$UI_G_WARN" "$1" "${2:-}"; }
ui_err() { ui__line "$UI_C_ERR" "$UI_G_ERR" "$1" "${2:-}" >&2; }
ui_skip() { ui__line "$UI_C_DIM" "$UI_G_SKIP" "$1" "${2:-}"; }
ui_run() { ui__line "$UI_C_INFO" "$UI_G_RUN" "$1" "${2:-}"; }
ui_backup() { ui__line "$UI_C_WARN" "$UI_G_BAK" "$1" "${2:-}"; }

# Ligne libre, sans glyphe ni libelle cadre.
ui_info() {
	printf '    %s%s%s\n' "$UI_C_DIM" "$1" "$UI_C_RESET"
}

ui_blank() { printf '\n'; }

# Erreur fatale : message puis sortie.
ui_die() {
	ui_err "${1:-erreur}" "${2:-}"
	exit "${3:-1}"
}

# ui_confirm "Installer les paquets ?"  -> 0 si oui
ui_confirm() {
	local question=$1 reponse

	[ "$UI_ASSUME_YES" = 1 ] && return 0

	# Sans terminal (CI, pipe) on ne bloque pas : on refuse par defaut.
	if [ ! -t 0 ]; then
		ui_skip "$question" "pas de terminal, etape ignoree"
		return 1
	fi

	printf '    %s%s%s [o/N] ' "$UI_C_BOLD" "$question" "$UI_C_RESET"
	read -r reponse
	case "$reponse" in
	[oO] | [oO][uU][iI] | [yY] | [yY][eE][sS]) return 0 ;;
	*) return 1 ;;
	esac
}

# --------------------------------------------------------------------------- #
#    Demo : ./lib/ui.sh pour visualiser le rendu                              #
# --------------------------------------------------------------------------- #

ui__demo() {
	ui_banner 'DEV-SETUP-HUB' 'demo'
	ui_section '1/2' 'Paquets systeme'
	ui_ok 'git' 'deja present'
	ui_run 'htop' 'installation...'
	ui_ok 'htop' 'installe'
	ui_skip 'thefuck' 'ignore (optionnel)'
	ui_warn 'autojump' 'absent du depot, a installer a la main'
	ui_blank
	ui_section '2/2' 'Shell - zsh'
	ui_backup '~/.zshrc' 'sauvegarde -> ~/.zshrc.bak.20260829-141200'
	ui_ok '~/.zshrc' 'deploye'
	ui_err '~/.zsh_aliases' 'source introuvable'
	ui_blank
	ui_info 'Ouvre un nouveau terminal zsh pour recharger la configuration.'
	ui_blank
}

# Sourcé -> rien. Exécuté directement -> demo.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	ui__demo
fi
