#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up Steam APT repository..."

# Fetch Steam official keyring
sudo curl -fsSL https://repo.steampowered.com/steam/archive/stable/steam.gpg \
    -o /usr/share/keyrings/steam-archive-keyring.gpg

sudo chmod 0644 /usr/share/keyrings/steam-archive-keyring.gpg

# Add repository (Steam requires i386 architecture support)
sudo dpkg --add-architecture i386

sudo tee /etc/apt/sources.list.d/steam.sources > /dev/null <<EOF
Types: deb
URIs: https://repo.steampowered.com/steam
Suites: stable
Components: steam
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/steam-archive-keyring.gpg
EOF