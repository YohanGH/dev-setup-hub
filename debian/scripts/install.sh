#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    install.sh                                          |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/07/22 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Orchestrateur : enchaîne la configuration complète d'un poste Debian/Ubuntu.
# Chaque étape est confirmée individuellement.
#
# Usage : ./install.sh [--yes]
#           --yes : exécute toutes les étapes sans confirmation
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

c_reset='\033[0m'; c_ok='\033[0;32m'; c_info='\033[0;34m'; c_warn='\033[0;33m'; c_bold='\033[1m'
log()  { printf "${c_info}[*]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_ok}[OK]${c_reset} %s\n" "$*"; }
warn() { printf "${c_warn}[!]${c_reset} %s\n" "$*"; }

AUTO=0
[ "${1:-}" = "--yes" ] && AUTO=1

banner() {
	cat <<'EOF'

   ###   ###  ### ###  ###   ###   ###
  ## ##  ###  ### ###  ## #  ###  ## ##
  ##### ## ## ###  ##  #####  #   #####
  ## ## ## ## ### ###  ## ##  #   ## ##
     A N K A M A  —  Configuration Debian

EOF
}

confirm() {
	# $1 = message ; retourne 0 si oui
	[ "$AUTO" -eq 1 ] && return 0
	printf "${c_bold}%s${c_reset} [o/N] " "$1"
	read -r ans
	case "$ans" in
		[oO]|[oO][uU][iI]|[yY]|[yY][eE][sS]) return 0 ;;
		*) return 1 ;;
	esac
}

run_step() {
	local script="$1" desc="$2"
	if confirm "→ $desc ?"; then
		log "Exécution : $script"
		bash "$SCRIPT_DIR/$script"
		ok "$desc terminé."
	else
		warn "Étape ignorée : $desc"
	fi
}

banner

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

run_step "init_debian.sh"    "1/4  Outils système + zsh + oh-my-zsh + powerlevel10k"
run_step "install_vim.sh"    "2/4  Configuration Vim (Prettier désactivé)"
run_step "set_header.sh"     "3/4  Header 42 personnalisé ANKAMA"
run_step "setup_obsidian.sh" "4/4  Coffre Obsidian ANKAMA_OBSIDIAN"

echo ''
ok "Installation terminée."
log "Pense à ouvrir un nouveau terminal zsh et à lancer 'p10k configure'."
