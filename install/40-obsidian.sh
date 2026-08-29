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
# coffre est propre a chaque poste, donc son chemin doit etre fourni :
#
#   ./install/40-obsidian.sh ~/Documents/MonCoffre
#   HUB_OBSIDIAN_VAULT=~/Documents/MonCoffre ./install/40-obsidian.sh
#
# Sans chemin, l'etape est ignoree plutot que d'ecrire au hasard.
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"

SRC="$HUB_ROOT/config/obsidian/obsidian"
VAULT="${1:-${HUB_OBSIDIAN_VAULT:-}}"

ui_section "${HUB_STEP:-4/5}" 'Obsidian'

# --- Coffre cible ----------------------------------------------------------- #
if [ -z "$VAULT" ]; then
	ui_skip 'coffre' 'aucun chemin fourni, etape ignoree'
	ui_info 'Relance en indiquant ton coffre :'
	ui_info '  ./install/40-obsidian.sh ~/chemin/vers/le/coffre'
	ui_blank
	exit 0
fi

# Deplie un eventuel ~ non interprete (cas d'une variable d'environnement).
VAULT="${VAULT/#\~/$HOME}"

[ -d "$VAULT" ] || ui_die "$(fs_short "$VAULT")" 'coffre introuvable'

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
