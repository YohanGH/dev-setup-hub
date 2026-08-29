#!/usr/bin/env bash
# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    00-packages.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2026/08/29 by YohanGH                    '__   _/_               #
#                                                     (___)=(___)              #
#                                                                              #
# **************************************************************************** #
# @desc: Paquets systeme
#
# Etape 1 : paquets systeme.
#
# Remplace la partie "dependances" de setup/setup-configs.sh (macOS) et de
# debian/scripts/init_debian.sh (Debian) par une source unique : profiles/.
#
# Lancable seul :  ./install/00-packages.sh
#
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/profile.sh
. "$(dirname "$_DIR")/lib/profile.sh"
# shellcheck source=lib/fs.sh
. "$(dirname "$_DIR")/lib/fs.sh"

ui_section "${HUB_STEP:-1/5}" 'Paquets systeme'

os_refuse_root
os_require

# --- Gestionnaire de paquets ----------------------------------------------- #
# Homebrew ne s'installe pas en silence : il demande une confirmation et les
# outils en ligne de commande Xcode. On oriente plutot que d'improviser.
if [ "$(pkg_manager)" = brew ] && ! has_cmd brew; then
	ui_err 'brew' 'Homebrew absent'
	ui_info 'Installe-le puis relance cette etape :'
	ui_info '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
	exit 1
fi

os_warm_sudo
pkg_refresh

# --- Paquets --------------------------------------------------------------- #
profile_install common
profile_install "$(os_id)"

# --- Applications graphiques ----------------------------------------------- #
# macOS seulement : sous Debian chaque application demande son propre depot
# tiers, elles sont documentees dans docs/MANUAL.md.
if [ "$(os_id)" = macos ]; then
	ui_blank
	ui_section "${HUB_STEP:-1/5}" 'Applications (Homebrew cask)'
	profile_install_cask macos-cask
fi

# --- Specificite Debian : fd ----------------------------------------------- #
# apt installe fd-find, dont le binaire s'appelle fdfind. On aligne le nom sur
# celui de macOS pour que les alias du zshrc marchent des deux cotes.
if [ "$(os_id)" = debian ] && ! has_cmd fd && has_cmd fdfind; then
	fs_ensure_dir "$HOME/.local/bin"
	ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
	ui_ok 'fd' 'lien -> fdfind (~/.local/bin)'
fi

ui_blank
