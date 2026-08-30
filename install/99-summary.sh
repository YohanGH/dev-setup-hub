#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    99-summary.sh                                       |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Verification et actions manuelles
#
# Derniere etape : etat du poste et actions restant a la main.
#
# Ne modifie rien. Lancable seul pour verifier une installation :
#   ./install/99-summary.sh
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$_DIR")"
# shellcheck source=lib/fs.sh
. "$HUB_ROOT/lib/fs.sh"
# shellcheck source=lib/os.sh
. "$HUB_ROOT/lib/os.sh"

ui_section "${HUB_STEP:-5/5}" 'Verification'

# --- Commandes attendues ---------------------------------------------------- #
for cmd in git zsh tmux tree htop fzf jq; do
	if has_cmd "$cmd"; then
		ui_ok "$cmd" "$(command -v "$cmd")"
	else
		ui_warn "$cmd" 'absent'
	fi
done

# --- Fichiers deployes ------------------------------------------------------ #
ui_blank
ui_section "${HUB_STEP:-5/5}" 'Configuration deployee'

verifier_lien() {
	local cible=$1

	if [ -L "$cible" ]; then
		ui_ok "$(fs_short "$cible")" "-> $(fs_short "$(readlink "$cible")")"
	elif [ -e "$cible" ]; then
		ui_warn "$(fs_short "$cible")" 'present mais pas lie au depot'
	else
		ui_warn "$(fs_short "$cible")" 'absent'
	fi
}

verifier_lien "$HOME/.zshrc"
verifier_lien "$HOME/.zsh_aliases"

if [ -d "$HOME/.oh-my-zsh" ]; then
	ui_ok 'oh-my-zsh' 'installe'
else
	ui_warn 'oh-my-zsh' 'absent'
fi

# --- Reste a faire a la main ------------------------------------------------ #
ui_blank
ui_section "${HUB_STEP:-5/5}" 'A faire a la main'

# shellcheck disable=SC2016 -- texte litteral a copier-coller, pas a executer
# maintenant : $(command -v zsh) doit rester tel quel dans le message.
[ "${SHELL:-}" = "$(command -v zsh)" ] ||
	ui_info 'Definir zsh par defaut :  chsh -s "$(command -v zsh)"'

ui_info 'Configurer le theme du prompt :  p10k configure'
ui_info 'Navigateurs : voir docs/MANUAL.md (hors installation auto)'

[ "$(os_id)" = debian ] &&
	ui_info 'Applications graphiques sous Debian : voir docs/MANUAL.md'

ui_info 'Rappels de maintenance (mises a jour, sauvegarde, audit) :  ./check.sh'

ui_blank
