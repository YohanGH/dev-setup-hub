#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    check.sh                                            |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/30 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Rappel de securite/maintenance : mises a jour, sauvegarde, audit — sur les
# dates d'execution uniquement. Frere de install.sh, pas une etape d'install.
#
#   ./check.sh              # etat de tous les controles
#   ./check.sh --done update   # enregistre "fait aujourd'hui"
#   ./check.sh --list           # liste les controles sans rien afficher d'autre
#
# Ce script ne lance JAMAIS une mise a jour, une sauvegarde ou un audit a ta
# place. Il compare une date a un seuil et rapporte ce qu'une commande de
# preuve, independante de cette date, observe sur le systeme — voir
# docs/CHECKS.md pour le detail de cette redondance.
#
set -euo pipefail

HUB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HUB_ROOT

# shellcheck source=lib/ui.sh
. "$HUB_ROOT/lib/ui.sh"
# shellcheck source=lib/checks.sh
. "$HUB_ROOT/lib/checks.sh"

# --------------------------------------------------------------------------- #
#    Arguments                                                                #
# --------------------------------------------------------------------------- #

MODE=afficher
CIBLE=''

while [ $# -gt 0 ]; do
	case "$1" in
	--done)
		shift
		[ $# -gt 0 ] || ui_die '--done' 'nom de controle attendu'
		MODE=marquer
		CIBLE=$1
		;;
	--list | -l)
		MODE=lister
		;;
	--help | -h)
		cat <<'EOF'
Usage : ./check.sh [option]

  (aucune)         affiche l'etat de tous les controles
  --done <nom>     enregistre <nom> comme fait aujourd'hui
  --list, -l       liste les controles declares, sans etat
  --help, -h       affiche cette aide

Ne lance jamais lui-meme une mise a jour, une sauvegarde ou un audit :
il rappelle qu'ils sont dus et affiche la commande a lancer.
EOF
		exit 0
		;;
	*)
		ui_die "$1" 'option inconnue, voir --help'
		;;
	esac
	shift
done

[ -f "$CHECKS_CONF" ] || ui_die 'checks.conf' 'manifeste introuvable'

# --------------------------------------------------------------------------- #
#    --done <nom>                                                             #
# --------------------------------------------------------------------------- #

if [ "$MODE" = marquer ]; then
	checks_load "$CIBLE" >/dev/null || ui_die "$CIBLE" 'controle inconnu, voir ./check.sh --list'
	checks_mark_done "$CIBLE"
	ui_ok "$CIBLE" "enregistre fait aujourd'hui ($(date +%Y-%m-%d))"
	exit 0
fi

# --------------------------------------------------------------------------- #
#    --list                                                                   #
# --------------------------------------------------------------------------- #

if [ "$MODE" = lister ]; then
	ui_section '--' 'Controles declares'
	while read -r nom; do
		[ -n "$nom" ] || continue
		sortie="$(checks_load "$nom")"
		ui_info "$(printf '%-10s %s' "$nom" "$(checks_field "$sortie" libelle)")"
	done < <(checks_list_names)
	ui_blank
	exit 0
fi

# --------------------------------------------------------------------------- #
#    Affichage de l'etat                                                      #
# --------------------------------------------------------------------------- #

ui_section "${HUB_STEP:--}" 'Verifications'

while read -r nom; do
	[ -n "$nom" ] || continue

	sortie="$(checks_load "$nom")"
	libelle="$(checks_field "$sortie" libelle)"
	seuil="$(checks_field "$sortie" seuil)"
	commande="$(checks_field "$sortie" commande)"
	derniere="$(checks_last_done "$nom")"

	if [ -z "$derniere" ]; then
		ui_missing "$libelle" 'jamais enregistre'
		ui_info "  $commande"
	else
		jours="$(checks_days_since "$derniere")"
		if [ -n "$jours" ] && [ "$jours" -le "$seuil" ]; then
			ui_ok "$libelle" "il y a $jours j (seuil $seuil j)"
		else
			ui_warn "$libelle" "il y a ${jours:-?} j (seuil $seuil j) — echeance depassee"
			ui_info "  $commande"
		fi
	fi

	# Preuve systeme : independante de la date declaree ci-dessus. Une ligne
	# non vide ici, meme quand la date declaree dit tout va bien, EST la
	# redondance que demande docs/CHECKS.md.
	preuve="$(checks_evidence "$sortie")"
	[ -z "$preuve" ] || ui_info "  systeme : $preuve"
done < <(checks_list_names)

ui_blank
