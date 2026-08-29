#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    github.sh                                           |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Interrogation de l'API GitHub publique : trouver la derniere release d'un
# depot, telecharger un asset ou l'archive source d'un tag, verifier une
# somme sha256.
#
# Volontairement DEGRADE PLUTOT QUE D'ECHOUER : sans lecteur JSON, sans reseau,
# ou en cas de limite de requetes atteinte, chaque fonction retourne simplement
# 1. L'appelant (install/50-external.sh) traite ca exactement comme « pas de
# release » et repart sur le clone Git — jamais comme une erreur fatale.
#
# Pourquoi pas /releases/latest : cet endpoint IGNORE les pre-releases. Les
# deux depots de ce hub sont actuellement des alpha marquees pre-release ;
# /releases/latest y repond 404. On liste donc /releases (qui les inclut) et
# on prend la premiere entree, la plus recente.
#
# A sourcer, pas a executer :  . lib/github.sh
#

[ -n "${_HUB_GITHUB_SH:-}" ] && return 0
_HUB_GITHUB_SH=1

_HUB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/os.sh
. "$_HUB_LIB_DIR/os.sh"

GITHUB_API_TIMEOUT="${GITHUB_API_TIMEOUT:-10}"

# --------------------------------------------------------------------------- #
#    Utilitaires                                                              #
# --------------------------------------------------------------------------- #

# github_owner_repo "https://github.com/YohanGH/Halo(.git)" -> "YohanGH/Halo"
github_owner_repo() {
	printf '%s' "$1" |
		sed -E -e 's#^https?://github\.com/##' -e 's#\.git/?$##' -e 's#/$##'
}

# gh, s'il est present et authentifie, donne un quota de requetes bien plus
# large que l'API publique anonyme (60/h). On l'utilise en priorite, sans en
# faire une dependance : curl reste le chemin par defaut.
github__via_gh() {
	has_cmd gh && gh auth status >/dev/null 2>&1
}

github__get() {
	local chemin=$1
	if github__via_gh; then
		gh api "$chemin" 2>/dev/null
	else
		curl -fsSL --max-time "$GITHUB_API_TIMEOUT" \
			-H 'Accept: application/vnd.github+json' \
			"https://api.github.com/$chemin" 2>/dev/null
	fi
}

# --------------------------------------------------------------------------- #
#    Lecture JSON : jq si present, sinon python3, sinon on renonce            #
# --------------------------------------------------------------------------- #

# Lit un tableau de releases sur stdin, imprime la plus recente sous forme :
#   TAG      <tag>
#   TARBALL  <url archive source>
#   ASSET    <nom>    <url de telechargement>
#   ...
# Rien sur stdout et code 1 si la liste est vide ou illisible.
github__parse_releases() {
	if has_cmd jq; then
		jq -r '
			if length == 0 then empty else
				.[0] as $r
				| "TAG\t\($r.tag_name)"
				, "TARBALL\t\($r.tarball_url)"
				, ($r.assets[]? | "ASSET\t\(.name)\t\(.browser_download_url)")
			end
		' 2>/dev/null
		return
	fi

	if has_cmd python3; then
		# python3 -c et non 'python3 - <<EOF' : ce dernier consomme stdin pour
		# lire le SCRIPT, alors que le JSON a parser arrive aussi par stdin —
		# les deux se disputent le meme canal et le script ne recoit rien.
		# Guillemets doubles partout dans le script, aucun simple : la
		# fonction bash l'encapsule entre guillemets simples.
		python3 -c '
import json, sys
try:
	data = json.load(sys.stdin)
except Exception:
	sys.exit(1)
if not data:
	sys.exit(1)
r = data[0]
print("TAG\t" + r.get("tag_name", ""))
print("TARBALL\t" + r.get("tarball_url", ""))
for a in r.get("assets") or []:
	print("ASSET\t" + a.get("name", "") + "\t" + a.get("browser_download_url", ""))
' 2>/dev/null
		return
	fi

	return 1
}

# --------------------------------------------------------------------------- #
#    API publique de la lib                                                   #
# --------------------------------------------------------------------------- #

# github_latest_release "YohanGH/Halo"
# Imprime TAG/TARBALL/ASSET (cf. ci-dessus) sur stdout, retourne 1 si :
# aucune release, pas de lecteur JSON, pas de reseau, limite atteinte.
github_latest_release() {
	local owner_repo=$1 brut

	brut="$(github__get "repos/$owner_repo/releases")" || return 1
	[ -n "$brut" ] || return 1

	printf '%s' "$brut" | github__parse_releases
}

# github_release_tag <sortie-de-github_latest_release>
github_release_tag() {
	printf '%s\n' "$1" | awk -F'\t' '$1=="TAG"{print $2; exit}'
}

github_release_tarball() {
	printf '%s\n' "$1" | awk -F'\t' '$1=="TARBALL"{print $2; exit}'
}

# github_release_asset_url <sortie> <indice-a-chercher-dans-le-nom>
# Cherche un asset dont le nom contient l'indice, en excluant les .sha256
# (sinon un indice generique matcherait la somme de controle elle-meme).
github_release_asset_url() {
	local sortie=$1 indice=$2
	printf '%s\n' "$sortie" |
		awk -F'\t' -v ind="$indice" '
			$1=="ASSET" && index($2, ind) > 0 && $2 !~ /\.sha256$/ { print $3; exit }
		'
}

# github_release_asset_sha256_url <sortie> <nom-de-l-asset>
github_release_asset_sha256_url() {
	local sortie=$1 nom=$2
	printf '%s\n' "$sortie" |
		awk -F'\t' -v n="$nom.sha256" '$1=="ASSET" && $2==n { print $3; exit }'
}

# --------------------------------------------------------------------------- #
#    Telechargement et verification                                           #
# --------------------------------------------------------------------------- #

# github_download <url> <fichier-destination>
github_download() {
	local url=$1 dest=$2
	curl -fsSL --max-time 120 -o "$dest" "$url" 2>/dev/null
}

# github_verify_sha256 <fichier> <fichier-de-somme>
# Le fichier de somme est au format standard "<hash>  <nom>". sha256sum et
# shasum verifient tous deux ce format ; macOS n'a que le second par defaut.
github_verify_sha256() {
	local fichier=$1 somme=$2 dossier nom

	dossier="$(dirname "$fichier")"
	nom="$(basename "$fichier")"

	(
		cd "$dossier" || exit 1
		if has_cmd sha256sum; then
			sha256sum -c "$somme" --ignore-missing >/dev/null 2>&1
		elif has_cmd shasum; then
			shasum -a 256 -c "$somme" --ignore-missing >/dev/null 2>&1
		else
			# Ni l'un ni l'autre : on ne peut pas verifier. L'appelant decide
			# s'il accepte ce risque ou s'il prefere s'abstenir.
			exit 2
		fi
	)
}
