#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    lint-shell.sh                                       |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Hook PreToolUse : passe shellcheck et shfmt avant un 'git commit'.
#
# Meme barriere que .github/workflows/ci.yml, mais en local — pour ne pas
# decouvrir a la CI ce qu'on pouvait savoir avant de commiter.
#
# Contrat :
#   entree  : JSON sur stdin, la commande est dans .tool_input.command
#   exit 0  : laisser passer
#   exit 2  : bloquer, le message sur stderr est rendu a Claude
#
# Ce hook echoue ouvert : si les outils manquent ou si l'entree est
# illisible, il laisse passer. Un verificateur de style n'a pas a empecher
# de travailler.
#
set -uo pipefail

RACINE="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Doit rester aligne sur LINT_PATHS dans .github/workflows/ci.yml.
CHEMINS=(lib install install.sh)

# --------------------------------------------------------------------------- #
#    Lecture de la commande                                                   #
# --------------------------------------------------------------------------- #

entree="$(cat)"

extraire_commande() {
	if command -v jq >/dev/null 2>&1; then
		printf '%s' "$entree" | jq -r '.tool_input.command // empty' 2>/dev/null
	elif command -v python3 >/dev/null 2>&1; then
		printf '%s' "$entree" | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: pass' 2>/dev/null
	fi
}

commande="$(extraire_commande)"
[ -n "$commande" ] || exit 0

# Ne se declenche que sur un vrai 'git commit', y compris en fin de chaine
# (&&, ;, |) et avec des options intercalees : 'git -C x commit'.
printf '%s' "$commande" |
	grep -qE '(^|[;&|]|\s)git\s+(-[^ ]+\s+)*commit(\s|$)' || exit 0

# --------------------------------------------------------------------------- #
#    Verifications                                                            #
# --------------------------------------------------------------------------- #

cd "$RACINE" 2>/dev/null || exit 0

fichiers=()
while IFS= read -r f; do
	fichiers+=("$f")
done < <(find "${CHEMINS[@]}" -name '*.sh' -print 2>/dev/null | sort)

[ "${#fichiers[@]}" -gt 0 ] || exit 0

problemes=''

# --- Syntaxe : toujours disponible, aucune excuse pour la sauter ----------- #
for f in "${fichiers[@]}"; do
	if ! sortie="$(bash -n "$f" 2>&1)"; then
		problemes+="erreur de syntaxe dans $f"$'\n'"$sortie"$'\n\n'
	fi
done

# --- shellcheck et shfmt : seulement s'ils sont installes ----------------- #
if command -v shellcheck >/dev/null 2>&1; then
	if ! sortie="$(shellcheck --shell=bash --external-sources --source-path=lib "${fichiers[@]}" 2>&1)"; then
		problemes+="shellcheck :"$'\n'"$sortie"$'\n\n'
	fi
fi

if command -v shfmt >/dev/null 2>&1; then
	if ! sortie="$(shfmt -d -ln bash "${fichiers[@]}" 2>&1)"; then
		problemes+="shfmt — indentation par tabulations attendue :"$'\n'"$sortie"$'\n\n'
	fi
fi

[ -z "$problemes" ] && exit 0

{
	printf 'Commit bloque : les scripts shell ne passent pas les verifications.\n\n'
	printf '%s' "$problemes"
	printf 'Corrige, puis relance le commit.\n'
} >&2
exit 2
