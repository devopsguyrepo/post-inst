#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Restoring local dotfiles with GNU Stow..."

# Resolve absolute path to script folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

if [ -d "$DOTFILES_DIR" ] && command -v stow &>/dev/null; then
    # Ensure SSH target directory exists with strict permissions before stowing
    mkdir -p -m 0700 "$HOME/.ssh"

    cd "$DOTFILES_DIR"
    for pkg in *; do
        [ -d "$pkg" ] || continue
        echo "   -> Stowing $pkg..."
        stow -R --target="$HOME" "$pkg"
    done
    echo -e "\e[32m[OK]\e[0m Dotfiles successfully symlinked to $HOME!"
else
    echo -e "\e[33m[WARN]\e[0m Dotfiles directory missing or 'stow' not installed. Skipping."
fi