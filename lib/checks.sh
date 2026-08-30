#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    checks.sh                                           |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/30 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Lecture de checks.conf, etat des dates dans un fichier TSV, et execution des
# commandes de preuve systeme. Utilise par check.sh.
#
# Perimetre volontairement etroit : cette lib ne lance jamais une mise a jour,
# une sauvegarde ou un audit. Elle compare des dates et rapporte ce qu'un
# controle systeme independant observe — rien de plus.
#
# A sourcer, pas a executer :  . lib/checks.sh
#

[ -n "${_HUB_CHECKS_SH:-}" ] && return 0
_HUB_CHECKS_SH=1

_HUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/os.sh
. "$_HUB_LIB_DIR/os.sh"

HUB_ROOT="${HUB_ROOT:-$(dirname "$_HUB_LIB_DIR")}"
CHECKS_CONF="${CHECKS_CONF:-$HUB_ROOT/checks.conf}"
CHECKS_STATE="${CHECKS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/dev-setup-hub/checks.tsv}"

# --------------------------------------------------------------------------- #
#    Lecture du manifeste                                                     #
# --------------------------------------------------------------------------- #

# checks_list_names — un nom de controle par ligne, dans l'ordre du fichier.
checks_list_names() {
	[ -f "$CHECKS_CONF" ] || return 0
	sed -n 's/^\[\(.*\)\]$/\1/p' "$CHECKS_CONF"
}

# checks_load <nom>
# Imprime les champs du bloc [nom] sous forme CLE<TAB>VALEUR, une ligne par
# cle — meme convention que github_latest_release dans lib/github.sh.
# Retourne 1 si le bloc n'existe pas.
checks_load() {
	local nom=$1
	[ -f "$CHECKS_CONF" ] || return 1

	awk -v nom="$nom" '
		/^\[.*\]$/ {
			dans = ($0 == "[" nom "]")
			next
		}
		dans && match($0, /^[a-z_]+[[:space:]]*=/) {
			cle = substr($0, 1, RSTART + RLENGTH - 2)
			gsub(/[[:space:]]+$/, "", cle)
			val = substr($0, RSTART + RLENGTH)
			sub(/^[[:space:]]/, "", val)
			print cle "\t" val
			trouve = 1
		}
		END { exit !trouve }
	' "$CHECKS_CONF"
}

checks_field() {
	printf '%s\n' "$1" | awk -F'\t' -v c="$2" '
		$1==c { sub(/^[^\t]*\t/, ""); print; f=1 }
		END   { exit !f }
	'
}

# --------------------------------------------------------------------------- #
#    Etat : date du dernier --done, par controle                              #
# --------------------------------------------------------------------------- #

checks__ensure_state() {
	mkdir -p "$(dirname "$CHECKS_STATE")"
	[ -f "$CHECKS_STATE" ] || : >"$CHECKS_STATE"
}

# checks_last_done <nom> — date ISO (AAAA-MM-JJ), vide si jamais enregistre.
checks_last_done() {
	[ -f "$CHECKS_STATE" ] || return 0
	awk -F'\t' -v n="$1" '$1==n{print $2}' "$CHECKS_STATE" | tail -1
}

# checks_mark_done <nom> [date-ISO]
# Enregistre la date (aujourd'hui par defaut). Remplace toute date anterieure
# pour ce controle plutot que d'empiler des lignes.
checks_mark_done() {
	local nom=$1 date=${2:-$(date +%Y-%m-%d)} tmp

	checks__ensure_state
	tmp="$(mktemp "${CHECKS_STATE}.XXXXXX")"

	awk -F'\t' -v n="$nom" '$1!=n' "$CHECKS_STATE" >"$tmp"
	printf '%s\t%s\n' "$nom" "$date" >>"$tmp"
	mv "$tmp" "$CHECKS_STATE"
}

# --------------------------------------------------------------------------- #
#    Arithmetique de dates : GNU date (-d) et BSD date (-j -f) different      #
# --------------------------------------------------------------------------- #

# checks__epoch <date-ISO> — secondes depuis epoch, ou vide si date illisible.
checks__epoch() {
	date -d "$1" +%s 2>/dev/null ||
		date -j -f '%Y-%m-%d' "$1" +%s 2>/dev/null
}

# checks_days_since <date-ISO> — entier, vide si la date est vide/invalide.
checks_days_since() {
	local d=$1 alors maintenant
	[ -n "$d" ] || return 0

	alors="$(checks__epoch "$d")"
	[ -n "$alors" ] || return 0

	maintenant="$(date +%s)"
	printf '%d' $(((maintenant - alors) / 86400))
}

# --------------------------------------------------------------------------- #
#    Preuve systeme                                                           #
# --------------------------------------------------------------------------- #

# checks_evidence <sortie-de-checks_load>
# Evalue la commande de preuve de la plateforme courante. Silencieuse = rien
# a signaler ; sinon imprime la ligne de diagnostic que la commande a rendue.
# Une preuve absente ou vide n'est pas une erreur : retour vide, silencieux.
checks_evidence() {
	local sortie=$1 cle cmd

	case "$(os_id)" in
	macos) cle=preuve_macos ;;
	*) cle=preuve_debian ;;
	esac

	cmd="$(checks_field "$sortie" "$cle")"
	[ -n "$cmd" ] || return 0

	eval "$cmd" 2>/dev/null
}
