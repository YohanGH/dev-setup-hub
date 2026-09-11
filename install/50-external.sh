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
# ferait deriver de l'amont, donc on ne les vendorise pas : on va chercher la
# derniere RELEASE (binaire si un correspond a la plateforme, sinon archive
# source figee sur son tag) et on ne clone la branche par defaut que si le
# depot n'a encore jamais publie de release.
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
# shellcheck source=lib/github.sh
. "$HUB_ROOT/lib/github.sh"

MANIFESTE="$HUB_ROOT/external.conf"
MARQUEUR='.dev-setup-hub-source'
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
has_cmd git || ui_die 'git' 'git est requis (repli si aucune release n existe)'
has_cmd curl || ui_die 'curl' 'curl est requis pour interroger GitHub'
has_cmd tar || ui_die 'tar' 'tar est requis pour extraire les archives'

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
#    Marqueur de version installee                                            #
# --------------------------------------------------------------------------- #

marqueur_lire_tag() {
	[ -f "$1/$MARQUEUR" ] || return 1
	cut -f1 "$1/$MARQUEUR"
}

marqueur_ecrire() {
	local dest=$1 tag=$2 genre=$3
	printf '%s\t%s\n' "$tag" "$genre" >"$dest/$MARQUEUR"
}

# --------------------------------------------------------------------------- #
#    Chemin 1 et 2 : release (binaire ou source figee)                        #
# --------------------------------------------------------------------------- #

# Place l'executable trouve a la racine de dest dans ~/.local/bin, pour qu'il
# soit utilisable immediatement sans connaitre le chemin interne — meme
# principe que le lien 'fd' cree par 00-packages.sh sous Debian.
lier_executable_si_present() {
	local nom=$1 dest=$2

	[ -x "$dest/$nom" ] || return 0

	fs_ensure_dir "$HOME/.local/bin"
	fs_link "$dest/$nom" "$HOME/.local/bin/$nom"
}

# recuperer_asset <nom> <dest> <sortie-github> <indice>
# Tente le binaire de release. Retourne 1 si aucun asset ne correspond : pas
# une erreur, juste "ce chemin ne s'applique pas", l'appelant essaiera la
# source.
recuperer_asset() {
	local nom=$1 dest=$2 sortie=$3 indice=$4
	local url_bin nom_bin url_sha tmp

	[ -n "$indice" ] || return 1

	url_bin="$(github_release_asset_url "$sortie" "$indice")"
	[ -n "$url_bin" ] || return 1
	nom_bin="$(basename "$url_bin")"

	ui_run "$nom" "telechargement de $nom_bin..."
	tmp="$(mktemp -d)"

	if ! github_download "$url_bin" "$tmp/$nom_bin"; then
		ui_warn "$nom" 'echec du telechargement, on retente via la source'
		rm -rf "$tmp"
		return 1
	fi

	url_sha="$(github_release_asset_sha256_url "$sortie" "$nom_bin")"
	if [ -n "$url_sha" ]; then
		if ! github_download "$url_sha" "$tmp/$nom_bin.sha256"; then
			ui_warn "$nom" 'somme de controle introuvable, verification ignoree'
		elif ! github_verify_sha256 "$tmp/$nom_bin" "$nom_bin.sha256"; then
			# Une somme qui ne correspond pas est un signal d'integrite, pas
			# une simple absence de release : on n'installe pas et on ne se
			# rabat PAS silencieusement sur la source non plus.
			ui_err "$nom" "somme de controle invalide pour $nom_bin — abandon"
			rm -rf "$tmp"
			return 2
		else
			ui_ok "$nom" 'somme de controle verifiee'
		fi
	fi

	fs_backup "$dest"
	fs_ensure_dir "$dest"
	tar -xzf "$tmp/$nom_bin" -C "$dest"
	rm -rf "$tmp"

	ui_ok "$nom" "binaire de release installe -> $(fs_short "$dest")"
	lier_executable_si_present "$nom" "$dest"
	return 0
}

# recuperer_source <nom> <dest> <sortie-github> <build>
# Archive source du tag, figee — jamais la branche par defaut. GitHub
# l'enveloppe dans un dossier owner-repo-sha/, d'ou le --strip-components=1.
recuperer_source() {
	local nom=$1 dest=$2 sortie=$3 build=$4
	local url_tarball tmp

	url_tarball="$(github_release_tarball "$sortie")"
	[ -n "$url_tarball" ] || return 1

	ui_run "$nom" 'telechargement de la source (release)...'
	tmp="$(mktemp -d)"

	if ! github_download "$url_tarball" "$tmp/source.tar.gz"; then
		ui_warn "$nom" 'echec du telechargement de la source'
		rm -rf "$tmp"
		return 1
	fi

	fs_backup "$dest"
	fs_ensure_dir "$dest"
	tar -xzf "$tmp/source.tar.gz" -C "$dest" --strip-components=1
	rm -rf "$tmp"

	ui_ok "$nom" "source (release) extraite -> $(fs_short "$dest")"
	construire "$nom" "$dest" "$build"
	return 0
}

construire() {
	local nom=$1 dest=$2 build=$3 outil

	[ -n "$build" ] || return 0

	outil=${build%% *}
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
#    Chemin 3 : repli Git, si le depot n'a encore jamais publie de release    #
# --------------------------------------------------------------------------- #

recuperer_git() {
	local nom=$1 url=$2 dest=$3 build=$4

	if [ -d "$dest/.git" ]; then
		ui_run "$nom" 'mise a jour (git, pas de release publiee)...'
		if git -C "$dest" pull --ff-only >/dev/null 2>&1; then
			ui_ok "$nom" "a jour ($(fs_short "$dest"))"
		else
			ui_warn "$nom" 'mise a jour impossible, depot laisse tel quel'
			return 0
		fi
	else
		ui_run "$nom" 'clonage (git, pas de release publiee)...'
		fs_ensure_dir "$(dirname "$dest")"
		if git clone --depth=1 "$url" "$dest" >/dev/null 2>&1; then
			ui_ok "$nom" "clone -> $(fs_short "$dest")"
		else
			ui_err "$nom" 'echec du clonage'
			return 1
		fi
	fi

	construire "$nom" "$dest" "$build"
}

# --------------------------------------------------------------------------- #
#    Repartition                                                              #
# --------------------------------------------------------------------------- #

recuperer() {
	local nom=$1 url=$2 dest=$3 build=$4 indice=$5
	local owner_repo sortie tag_distant tag_installe

	owner_repo="$(github_owner_repo "$url")"
	sortie="$(github_latest_release "$owner_repo" 2>/dev/null || true)"

	if [ -z "$sortie" ]; then
		# Ni release trouvee, ni lecteur JSON, ni reseau : on ne sait pas
		# distinguer ces cas depuis ici, et le resultat est le meme dans les
		# trois — repli sur Git, le seul chemin qui ne depend de rien de ca.
		recuperer_git "$nom" "$url" "$dest" "$build"
		return
	fi

	tag_distant="$(github_release_tag "$sortie")"
	tag_installe="$(marqueur_lire_tag "$dest" 2>/dev/null || true)"

	if [ "$tag_distant" = "$tag_installe" ]; then
		ui_ok "$nom" "a jour ($tag_distant)"
		lier_executable_si_present "$nom" "$dest"
		return 0
	fi

	if recuperer_asset "$nom" "$dest" "$sortie" "$indice"; then
		marqueur_ecrire "$dest" "$tag_distant" 'release-binaire'
		return 0
	elif [ $? -eq 2 ]; then
		# Somme de controle invalide : deja signale, on n'ecrit pas de
		# marqueur pour qu'un prochain passage retente plutot que de croire
		# l'installation a jour.
		return 1
	fi

	if recuperer_source "$nom" "$dest" "$sortie" "$build"; then
		marqueur_ecrire "$dest" "$tag_distant" 'release-source'
		return 0
	fi

	ui_warn "$nom" 'release inexploitable, repli sur Git'
	recuperer_git "$nom" "$url" "$dest" "$build"
}

# --------------------------------------------------------------------------- #
#    Lecture du manifeste                                                     #
# --------------------------------------------------------------------------- #

courante="$(plateforme_courante)"
traites=0
echecs=0

while IFS='|' read -r nom url dest plateforme defaut build indice; do
	# Nettoyage des espaces de mise en forme du manifeste.
	nom="$(printf '%s' "$nom" | tr -d '[:space:]')"
	url="$(printf '%s' "$url" | tr -d '[:space:]')"
	dest="$(printf '%s' "$dest" | tr -d '[:space:]')"
	plateforme="$(printf '%s' "$plateforme" | tr -d '[:space:]')"
	defaut="$(printf '%s' "$defaut" | tr -d '[:space:]')"
	build="$(printf '%s' "${build:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	indice="$(printf '%s' "${indice:-}" | tr -d '[:space:]')"

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

	# Le || true laisse la boucle continuer sur les AUTRES entrees apres un
	# echec — mais un echec doit tout de meme se voir dans le code de sortie
	# du script, sans quoi une somme de controle invalide ou un clone rate
	# ressortirait en 0 comme si tout s'etait bien passe.
	if recuperer "$nom" "$url" "${dest/#\~/$HOME}" "$build" "$indice"; then
		:
	else
		echecs=$((echecs + 1))
	fi
	traites=$((traites + 1))
done <"$MANIFESTE"

[ "$traites" -gt 0 ] || ui_info 'Aucun depot a recuperer sur cette plateforme.'

ui_blank

[ "$echecs" -eq 0 ]
