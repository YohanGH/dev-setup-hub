#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    30-editor.sh                                        |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Editeurs — VSCode et VSCodium, config identique
#
# Etape : deploie la MEME configuration dans VSCode et VSCodium.
#
# config/editor/ est la source unique : settings.json, keybindings.json et
# extensions.list. Les deux editeurs recoivent des copies identiques.
#
#   ./install/30-editor.sh                 # config + extensions
#   ./install/30-editor.sh --no-extensions # config seulement
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

SRC="$HUB_ROOT/config/editor"
AVEC_EXTENSIONS=1

[ "${1:-}" = '--no-extensions' ] && AVEC_EXTENSIONS=0

ui_section "${HUB_STEP:-5/8}" 'Editeurs — VSCode et VSCodium'

# --------------------------------------------------------------------------- #
#    Emplacements                                                             #
# --------------------------------------------------------------------------- #

# Le dossier User differe par OS mais pas par editeur : seul le nom du produit
# change entre Code et VSCodium.
dossier_user() {
	case "$(os_id)" in
	macos) printf '%s/Library/Application Support/%s/User' "$HOME" "$1" ;;
	*) printf '%s/.config/%s/User' "$HOME" "$1" ;;
	esac
}

# --------------------------------------------------------------------------- #
#    Deploiement                                                              #
# --------------------------------------------------------------------------- #

# deployer <nom-affiche> <nom-produit> <commande-cli>
deployer() {
	local libelle=$1 produit=$2 cli=$3 dest
	dest="$(dossier_user "$produit")"

	# Ni l'application ni son dossier de reglages : l'editeur n'est pas la.
	if ! has_cmd "$cli" && [ ! -d "$dest" ]; then
		ui_skip "$libelle" 'non installe, ignore'
		return 0
	fi

	# Copie et non lien : VSCode reecrit settings.json par ecriture atomique
	# (fichier temporaire puis rename), ce qui remplacerait un lien symbolique
	# par un fichier ordinaire des la premiere modification via l'interface.
	fs_copy "$SRC/settings.json" "$dest/settings.json"
	fs_copy "$SRC/keybindings.json" "$dest/keybindings.json"

	[ "$AVEC_EXTENSIONS" -eq 1 ] || return 0
	has_cmd "$cli" || {
		ui_skip "$libelle" "commande '$cli' absente, extensions ignorees"
		return 0
	}

	installer_extensions "$libelle" "$cli"
}

# installer_extensions <nom-affiche> <commande-cli>
installer_extensions() {
	local libelle=$1 cli=$2 id obligatoire installees

	# Une seule interrogation de la CLI : elle est lente a demarrer.
	installees="$("$cli" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

	while read -r id; do
		[ -n "$id" ] || continue

		obligatoire=1
		case "$id" in '!'*) obligatoire=0; id="${id#!}" ;; esac

		if printf '%s\n' "$installees" | grep -qxF "$(printf '%s' "$id" | tr '[:upper:]' '[:lower:]')"; then
			ui_ok "$id" "deja present ($libelle)"
			continue
		fi

		if "$cli" --install-extension "$id" --force >/dev/null 2>&1; then
			ui_ok "$id" "installe ($libelle)"
		elif [ "$obligatoire" -eq 1 ]; then
			ui_warn "$id" "echec ($libelle)"
		else
			# Cas attendu pour VSCodium : l'extension n'est pas sur Open VSX.
			ui_skip "$id" "indisponible sur ce registre ($libelle)"
		fi
	done < <(sed -e 's/#.*$//' -e 's/[[:space:]]//g' "$SRC/extensions.list" | grep -v '^$')
}

[ -f "$SRC/settings.json" ] || ui_die 'settings.json' 'introuvable dans config/editor/'

deployer 'VSCodium' 'VSCodium' 'codium'
deployer 'VSCode' 'Code' 'code'

ui_blank
