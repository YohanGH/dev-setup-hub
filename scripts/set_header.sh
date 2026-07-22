#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    set_header.sh                                       |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/07/22 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Installe le header 42 personnalisé "ANKAMA" (plugin Vim stdheader.vim) et
# exporte USER / MAIL pour renseigner automatiquement l'en-tête.
#
# Usage : ./set_header.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEADER_SRC="$SCRIPT_DIR/assets/stdheader.vim"

c_reset='\033[0m'; c_ok='\033[0;32m'; c_info='\033[0;34m'; c_warn='\033[0;33m'
log()  { printf "${c_info}[*]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_ok}[OK]${c_reset} %s\n" "$*"; }
warn() { printf "${c_warn}[!]${c_reset} %s\n" "$*"; }

[ -f "$HEADER_SRC" ] || { warn "Introuvable : $HEADER_SRC"; exit 1; }

# --- 1. Exports USER / MAIL dans ~/.zshrc (idempotent) -------------------- #
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

if ! grep -q '^export USER=' "$ZSHRC"; then
	{
		echo ''
		echo '# Header 42 - identité (ajouté par set_header.sh)'
		echo "export USER=\"$(/usr/bin/whoami)\""
		echo "export MAIL=\"\${USER}@proton.me\""
	} >> "$ZSHRC"
	ok "USER / MAIL exportés dans ~/.zshrc."
else
	ok "USER déjà exporté dans ~/.zshrc."
fi

# --- 2. Installation du plugin header ------------------------------------- #
mkdir -p "$HOME/.vim/plugin"
cp "$HEADER_SRC" "$HOME/.vim/plugin/stdheader.vim"
ok "Header ANKAMA installé : ~/.vim/plugin/stdheader.vim"

# --- 3. Rappel identité dans .vimrc (fallback si USER/MAIL absents) -------- #
if [ -f "$HOME/.vimrc" ] && ! grep -q "g:userName" "$HOME/.vimrc"; then
	{
		echo ''
		echo '" Identité header (ajouté par set_header.sh)'
		echo "let g:userName = 'YohanGH'"
		echo "let g:mailName = 'YohanGH@proton.me'"
	} >> "$HOME/.vimrc"
	ok "Identité header ajoutée au ~/.vimrc."
fi

cat <<'EOF'

  Header ANKAMA prêt.
  Ouvre un fichier dans vim puis appuie sur F1 (ou :Stdheader) :

  /* ************************************************************************** */
  /*                                A N K A M A                                 */
  /*                                A N K A M A                                 */
  /*                                                                            */
  /*                                                    .--.    No              */
  ...

EOF
ok "Configuration du header terminée."
