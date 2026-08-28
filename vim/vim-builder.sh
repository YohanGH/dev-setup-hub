#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    vim-builder.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/28 17:27:09 by YohanGH           '__   _/_               #
#    Updated: 2026/08/28 17:46:43 by YohanGH          (___)=(___)              #
#                                                                              #
# **************************************************************************** #

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vimrc="$repo/.vimrc"

# Fragments sourcés par .vimrc, dans l'ordre de chargement.
fragments=(.vim.base .vim.shortcut .vim.functions .vim.plugins)

begin_mark='" >>> vim-builder >>>'
end_mark='" <<< vim-builder <<<'

tmp=""
cleanup() {
	[[ -n $tmp ]] && rm -f "$tmp"
	return 0
}
trap cleanup EXIT

# Statut en ASCII : printf pade en octets, les accents casseraient l'alignement.
say() {
	printf '%-9s %s\n' "$1" "$2"
}

# --------------------------------------------------------------------------- #
#    Vérification des fragments                                               #
# --------------------------------------------------------------------------- #

check_fragments() {
	local f

	for f in "${fragments[@]}"; do
		if [[ ! -f $repo/$f ]]; then
			say absent "$f"
		elif [[ ! -s $repo/$f ]]; then
			say vide "$f"
		else
			say ok "$f"
		fi
	done
}

# --------------------------------------------------------------------------- #
#    Génération du .vimrc                                                     #
# --------------------------------------------------------------------------- #

# Bloc de chargement injecté dans .vimrc. resolve() suit le lien symbolique
# ~/.vimrc pour retrouver le dépôt, quel que soit le cwd au démarrage de vim.
build_block() {
	local f

	echo "$begin_mark"
	echo '" Généré par vim-builder.sh — ne pas éditer à la main.'
	echo "let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h')"
	echo
	for f in "${fragments[@]}"; do
		echo "let s:frag = s:root . '/$f'"
		echo "if filereadable(s:frag) | execute 'source' fnameescape(s:frag) | endif"
	done
	echo "$end_mark"
}

build_vimrc() {
	tmp="$(mktemp "${TMPDIR:-/tmp}/vimrc.XXXXXX")"

	# Le .vimrc du dépôt était un lien symbolique cassé : on le supprime.
	if [[ -L $vimrc && ! -e $vimrc ]]; then
		rm "$vimrc"
		say clean ".vimrc (lien cassé)"
	fi

	if [[ ! -e $vimrc ]]; then
		say cree ".vimrc"
	elif [[ ! -s $vimrc ]]; then
		say rempli ".vimrc (était vide)"
	else
		# Recopie tout sauf l'ancien bloc généré, pour rester idempotent
		# sans écraser ce que tu aurais ajouté à la main.
		awk -v b="$begin_mark" -v e="$end_mark" '
			$0 == b { skip = 1; next }
			$0 == e { skip = 0; next }
			!skip
		' "$vimrc" > "$tmp"
		say maj ".vimrc"
	fi

	build_block >> "$tmp"
	cat "$tmp" > "$vimrc"
}

# --------------------------------------------------------------------------- #
#    Lien symbolique vers $HOME                                               #
# --------------------------------------------------------------------------- #

link() {
	local src="$repo/$1" dst="$HOME/$1"

	[[ -e $src ]] || { echo "source absente : $src" >&2; return 1; }

	# déjà bon → rien à faire
	if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
		say ok "$dst"
		return 0
	fi

	# un vrai fichier existe → on l'archive
	if [[ -e $dst && ! -L $dst ]]; then
		mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
		say backup "$dst.bak.*"
	fi

	ln -sfn "$src" "$dst"
	say lien "$dst -> $src"
}

# --------------------------------------------------------------------------- #
#    Main                                                                     #
# --------------------------------------------------------------------------- #

main() {
	check_fragments
	build_vimrc
	link .vimrc
}

main "$@"
