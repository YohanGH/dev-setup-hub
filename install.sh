#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    install.sh                                          |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Point d'entree unique. Detecte l'OS et enchaine les etapes de install/.
#
#   ./install.sh              # interactif, confirmation par etape
#   ./install.sh --yes        # tout enchainer sans confirmation
#   ./install.sh --list       # lister les etapes sans rien executer
#   ./install.sh --only 10    # ne lancer que l'etape 10-shell.sh
#
# Chaque etape reste lancable seule :  ./install/10-shell.sh
#
set -euo pipefail

HUB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HUB_ROOT

# shellcheck source=lib/ui.sh
. "$HUB_ROOT/lib/ui.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

# --------------------------------------------------------------------------- #
#    Arguments                                                                #
# --------------------------------------------------------------------------- #

MODE=run
FILTRE=''

while [ $# -gt 0 ]; do
	case "$1" in
	--yes | -y)
		UI_ASSUME_YES=1
		;;
	--list | -l)
		MODE=list
		;;
	--only)
		shift
		[ $# -gt 0 ] || ui_die '--only' 'prefixe d etape attendu (ex: 10)'
		FILTRE="$1"
		;;
	--help | -h)
		cat <<'EOF'
Usage : ./install.sh [option]

  (aucune)      interactif, une confirmation par etape
  --yes, -y     enchaine tout sans confirmation
  --list, -l    liste les etapes sans rien executer
  --only <n>    ne lance que l'etape dont le nom commence par <n> (ex: 10)
  --help, -h    affiche cette aide

Chaque etape reste lancable seule :  ./install/10-shell.sh
EOF
		exit 0
		;;
	*)
		ui_die "$1" 'option inconnue, voir --help'
		;;
	esac
	shift
done

export UI_ASSUME_YES

# --------------------------------------------------------------------------- #
#    Registre des etapes                                                      #
# --------------------------------------------------------------------------- #

# Les etapes sont decouvertes dans install/, triees par leur prefixe numerique.
# Ajouter une etape = deposer un fichier, rien a modifier ici. Sa description
# est lue depuis la ligne '# @desc:' du script.
etapes=()
while IFS= read -r f; do
	etapes+=("$f")
done < <(find "$HUB_ROOT/install" -maxdepth 1 -name '*.sh' -print 2>/dev/null | sort)

[ "${#etapes[@]}" -gt 0 ] || ui_die 'install/' 'aucune etape trouvee'

description() {
	local desc
	desc="$(sed -n 's/^# @desc: *//p' "$1" | head -1)"
	printf '%s' "${desc:-$(basename "$1" .sh)}"
}

# --------------------------------------------------------------------------- #
#    Execution                                                                #
# --------------------------------------------------------------------------- #

os_require

ui_banner 'DEV-SETUP-HUB' "$(os_label)"

if [ "$MODE" = list ]; then
	ui_section '--' 'Etapes disponibles'
	for f in "${etapes[@]}"; do
		ui_info "$(printf '%-18s %s' "$(basename "$f")" "$(description "$f")")"
	done
	ui_blank
	exit 0
fi

total="${#etapes[@]}"
numero=0
echecs=0

for f in "${etapes[@]}"; do
	numero=$((numero + 1))
	nom="$(basename "$f")"

	# --only 10 ne garde que les etapes dont le nom commence par ce prefixe.
	if [ -n "$FILTRE" ] && [ "${nom#"$FILTRE"}" = "$nom" ]; then
		continue
	fi

	desc="$(description "$f")"

	# Sans --yes ni --only, chaque etape est confirmee separement.
	if [ -z "$FILTRE" ] && ! ui_confirm "$desc ?"; then
		ui_skip "$nom" 'etape ignoree'
		ui_blank
		continue
	fi

	# HUB_STEP alimente le compteur affiche par l'etape elle-meme.
	if HUB_STEP="$numero/$total" bash "$f"; then
		:
	else
		echecs=$((echecs + 1))
		ui_err "$nom" 'etape en echec, on poursuit'
		ui_blank
	fi
done

# --------------------------------------------------------------------------- #
#    Bilan                                                                    #
# --------------------------------------------------------------------------- #

if [ "$echecs" -eq 0 ]; then
	ui_ok 'installation' 'terminee'
else
	ui_warn 'installation' "terminee avec $echecs etape(s) en echec"
fi

ui_blank

# Le code de sortie doit refleter les echecs : sans ca, un pipeline ou un
# 'full' de CI qui teste ./install.sh --yes ne peut jamais detecter qu'une
# etape a reellement echoue en dessous.
[ "$echecs" -eq 0 ]
