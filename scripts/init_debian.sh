#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    init_debian.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/07/22 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
#
# Initialise un poste Debian / Ubuntu :
#   - vérifie / installe les commandes utiles (curl htop tree fd python3 tmux)
#   - installe oh-my-zsh + powerlevel10k
#   - déploie la configuration zsh (zshrc + alias)
#
# Usage : ./init_debian.sh
#
set -euo pipefail

# --- Repérage des chemins -------------------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ZSH_SRC="$REPO_DIR/Configuration_zshrc"

# --- Couleurs / logs ------------------------------------------------------- #
c_reset='\033[0m'; c_ok='\033[0;32m'; c_info='\033[0;34m'; c_warn='\033[0;33m'
log()  { printf "${c_info}[*]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_ok}[OK]${c_reset} %s\n" "$*"; }
warn() { printf "${c_warn}[!]${c_reset} %s\n" "$*"; }

# --- Garde-fous ------------------------------------------------------------ #
if [ "$(id -u)" -eq 0 ]; then
	warn "Ne lancez pas ce script en root. Il utilisera 'sudo' au besoin."
	exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
	warn "apt-get introuvable : ce script cible Debian / Ubuntu."
	exit 1
fi

# --- 1. Paquets système ---------------------------------------------------- #
# Table : commande_attendue -> paquet_apt
declare -A PKGS=(
	[curl]=curl
	[htop]=htop
	[tree]=tree
	[fd]=fd-find          # "fs" du cahier des charges -> fd-find (binaire fdfind)
	[python3]=python3
	[tmux]=tmux
	[zsh]=zsh
	[git]=git
)

log "Mise à jour de l'index des paquets…"
sudo apt-get update -y

TO_INSTALL=()
for cmd in "${!PKGS[@]}"; do
	if command -v "$cmd" >/dev/null 2>&1; then
		ok "commande présente : $cmd"
	else
		warn "manquante : $cmd -> paquet ${PKGS[$cmd]}"
		TO_INSTALL+=("${PKGS[$cmd]}")
	fi
done

# fdfind est parfois installé sans alias 'fd'
if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
	TO_INSTALL+=(fd-find)
fi

if [ "${#TO_INSTALL[@]}" -gt 0 ]; then
	log "Installation : ${TO_INSTALL[*]}"
	sudo apt-get install -y "${TO_INSTALL[@]}"
else
	ok "Toutes les commandes système sont déjà installées."
fi

# Crée l'alias 'fd' -> 'fdfind' (spécificité Debian)
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
	mkdir -p "$HOME/.local/bin"
	ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
	ok "Alias créé : ~/.local/bin/fd -> fdfind"
fi

# --- 2. oh-my-zsh ---------------------------------------------------------- #
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [ -d "$ZSH" ]; then
	ok "oh-my-zsh déjà présent."
else
	log "Installation de oh-my-zsh (mode non interactif)…"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	ok "oh-my-zsh installé."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# --- 3. powerlevel10k ------------------------------------------------------ #
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
	ok "powerlevel10k déjà présent."
else
	log "Clonage de powerlevel10k…"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
	ok "powerlevel10k installé."
fi

# --- 4. Plugins zsh externes ---------------------------------------------- #
clone_plugin() {
	local name="$1" url="$2" dest="$ZSH_CUSTOM/plugins/$1"
	if [ -d "$dest" ]; then
		ok "plugin déjà présent : $name"
	else
		log "Clonage du plugin : $name"
		git clone --depth=1 "$url" "$dest"
	fi
}
clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# autojump / thefuck (référencés dans le zshrc)
if ! command -v autojump >/dev/null 2>&1; then
	sudo apt-get install -y autojump || warn "autojump non installé (optionnel)."
fi
if ! command -v thefuck >/dev/null 2>&1; then
	sudo apt-get install -y thefuck || warn "thefuck non installé (optionnel)."
fi

# --- 5. Déploiement de la configuration zsh ------------------------------- #
backup() { [ -e "$1" ] && cp -a "$1" "$1.bak.$(date +%Y%m%d%H%M%S)" && warn "Sauvegarde : $1.bak"; }

if [ -f "$ZSH_SRC/zshrc" ]; then
	backup "$HOME/.zshrc"
	cp "$ZSH_SRC/zshrc" "$HOME/.zshrc"
	ok "~/.zshrc déployé."
fi

# Alias supplémentaires -> chargés depuis ~/.zsh_aliases
if [ -f "$ZSH_SRC/my-alias-v2.zsh" ]; then
	cp "$ZSH_SRC/my-alias-v2.zsh" "$HOME/.zsh_aliases"
	if ! grep -q '.zsh_aliases' "$HOME/.zshrc" 2>/dev/null; then
		printf '\n# Alias personnalisés\n[[ ! -f ~/.zsh_aliases ]] || source ~/.zsh_aliases\n' >> "$HOME/.zshrc"
	fi
	ok "Alias déployés (~/.zsh_aliases)."
fi

# Ajoute ~/.local/bin au PATH si nécessaire
if ! grep -q 'HOME/.local/bin' "$HOME/.zshrc" 2>/dev/null; then
	printf '\n# Binaries utilisateur\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
fi

# --- 6. Shell par défaut --------------------------------------------------- #
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
	warn "Pour définir zsh comme shell par défaut :  chsh -s \"\$(command -v zsh)\""
fi

ok "Initialisation Debian terminée. Ouvrez un nouveau terminal zsh."
