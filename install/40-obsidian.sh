#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    40-obsidian.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Obsidian — reglages du coffre
#
# Etape 4 : configuration Obsidian.
#
# Deploie les reglages dans le dossier .obsidian d'un coffre existant. Un
# coffre est propre a chaque poste : son chemin n'est donc jamais code en dur.
# L'etape le resout dans cet ordre, et ne s'arrete qu'en dernier recours :
#
#   1. l'argument ou HUB_OBSIDIAN_VAULT
#   2. les coffres qu'Obsidian a lui-meme enregistres dans obsidian.json
#   3. un balayage de $HOME a la recherche de dossiers .obsidian
#   4. rien de tout ca -> etape ignoree plutot que d'ecrire au hasard
#
#   ./install/40-obsidian.sh ~/Documents/MonCoffre
#   HUB_OBSIDIAN_VAULT=~/Documents/MonCoffre ./install/40-obsidian.sh
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"

SRC="$HUB_ROOT/config/obsidian/obsidian"
VAULT="${1:-${HUB_OBSIDIAN_VAULT:-}}"

ui_section "${HUB_STEP:-4/5}" 'Obsidian'

# --------------------------------------------------------------------------- #
#    Decouverte des coffres                                                   #
# --------------------------------------------------------------------------- #

# Le registre d'Obsidian : son chemin depend de l'OS, comme dossier_user()
# dans 30-editor.sh. Une fonction locale a l'etape, pas un branchement — la
# difference est un chemin, elle appartient ici et pas a lib/os.sh.
registres_obsidian() {
	printf '%s\n' \
		"$HOME/Library/Application Support/obsidian/obsidian.json" \
		"$HOME/.config/obsidian/obsidian.json" \
		"$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json" \
		"$HOME/snap/obsidian/current/.config/obsidian/obsidian.json"
}

# Coffres declares par Obsidian lui-meme. C'est la source la plus fiable :
# l'application y note chaque coffre ouvert. Extraction au grep plutot qu'avec
# jq — jq est optionnel dans profiles/, et une seule cle est recherchee.
coffres_declares() {
	local registre
	while read -r registre; do
		[ -r "$registre" ] || continue
		grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' "$registre" 2>/dev/null |
			sed -e 's/^"path"[[:space:]]*:[[:space:]]*"//' -e 's/"$//'
	done < <(registres_obsidian)
}

# Repli quand le registre est absent ou vide : un coffre est un dossier qui
# contient .obsidian. Profondeur bornee, et Library / node_modules / dossiers
# caches elagues — sans quoi le balayage passerait l'essentiel de son temps
# dans des arborescences ou aucun coffre ne se trouve jamais.
coffres_trouves() {
	find "$HOME" -maxdepth 4 \
		\( -name Library -o -name node_modules -o \( -name '.[!.]*' ! -name .obsidian \) \) -prune \
		-o -type d -name .obsidian -print 2>/dev/null |
		while read -r d; do printf '%s\n' "$(dirname "$d")"; done
}

# Liste dedupliquee des coffres reellement presents sur le disque.
coffres() {
	{
		coffres_declares
		coffres_trouves
	} | while read -r c; do
		[ -n "$c" ] && [ -d "$c" ] && printf '%s\n' "${c%/}"
	done | awk '!vu[$0]++'
}

# --------------------------------------------------------------------------- #
#    Coffre cible                                                             #
# --------------------------------------------------------------------------- #

if [ -z "$VAULT" ]; then
	candidats=()
	while IFS= read -r c; do
		[ -n "$c" ] && candidats+=("$c")
	done < <(coffres)

	case "${#candidats[@]}" in
	0)
		ui_skip 'coffre' 'aucun coffre Obsidian trouve, etape ignoree'
		ui_info 'Cree ton coffre dans Obsidian, ou indique-le a la main :'
		ui_info '  ./install/40-obsidian.sh ~/chemin/vers/le/coffre'
		ui_blank
		exit 0
		;;
	1)
		# Un seul candidat : on le propose plutot que de l'imposer. Ecrire
		# dans un coffre, c'est remplacer des reglages existants.
		ui_ok 'coffre' "$(fs_short "${candidats[0]}")"
		if ui_confirm "Deployer les reglages dans $(fs_short "${candidats[0]}") ?"; then
			VAULT="${candidats[0]}"
		else
			ui_skip 'coffre' 'refuse, etape ignoree'
			ui_blank
			exit 0
		fi
		;;
	*)
		ui_info 'Plusieurs coffres trouves :'
		for i in "${!candidats[@]}"; do
			ui_info "  $((i + 1))) $(fs_short "${candidats[$i]}")"
		done

		if [ ! -t 0 ]; then
			ui_skip 'coffre' 'plusieurs candidats et pas de terminal, etape ignoree'
			ui_blank
			exit 0
		fi

		printf '    Lequel ? [1-%d, vide pour ignorer] ' "${#candidats[@]}"
		read -r choix
		case "$choix" in
		'' | *[!0-9]*)
			ui_skip 'coffre' 'aucun choix, etape ignoree'
			ui_blank
			exit 0
			;;
		esac
		if [ "$choix" -lt 1 ] || [ "$choix" -gt "${#candidats[@]}" ]; then
			ui_die "$choix" 'numero hors liste'
		fi
		VAULT="${candidats[$((choix - 1))]}"
		;;
	esac
fi

# Deplie un eventuel ~ non interprete (cas d'une variable d'environnement).
VAULT="${VAULT/#\~/$HOME}"
VAULT="${VAULT%/}"

[ -d "$VAULT" ] || ui_die "$(fs_short "$VAULT")" 'coffre introuvable'

# Le chemin du coffre est propre au poste : il va dans ~/.zsh_local, jamais
# versionne, pour que la prochaine execution n'ait plus rien a demander.
fs_append_once "$HOME/.zsh_local" 'HUB_OBSIDIAN_VAULT=' \
	'# Coffre Obsidian cible par ./install/40-obsidian.sh.' \
	"export HUB_OBSIDIAN_VAULT=\"$VAULT\""

DEST="$VAULT/.obsidian"

# --- Reglages --------------------------------------------------------------- #
# Fichiers de reglages uniquement. Les plugins tiers ne sont pas versionnes :
# 22 Mo de JavaScript compile appartenant a d'autres projets. Attention,
# community-plugins.json n'est PAS une liste d'installation, c'est la liste des
# plugins ACTIVES : Obsidian n'y cherche rien a telecharger. La reinstallation
# se fait par l'interface. Inventaire dans config/obsidian/plugins.md.
for f in app.json appearance.json core-plugins.json \
	core-plugins-migration.json community-plugins.json hotkeys.json; do
	if [ -f "$SRC/$f" ]; then
		fs_copy "$SRC/$f" "$DEST/$f"
	else
		ui_skip "$f" 'absent du depot'
	fi
done

# --- Themes ----------------------------------------------------------------- #
# Ceux-ci sont maison ou modifies : Obsidian ne sait pas les retrouver seul.
if [ -d "$SRC/themes" ]; then
	for theme in "$SRC"/themes/*/; do
		[ -d "$theme" ] || continue
		fs_copy "${theme%/}" "$DEST/themes/$(basename "$theme")"
	done
fi

ui_info 'Les plugins communautaires ne sont pas deployes : Obsidian ne les'
ui_info 'reinstalle pas seul. Liste et procedure dans config/obsidian/plugins.md.'
ui_blank
