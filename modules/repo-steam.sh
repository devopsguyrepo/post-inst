#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up Steam repository..."

# Clean up any existing Steam source files to avoid "Conflicting values set for option Signed-By"
sudo rm -f /etc/apt/sources.list.d/steam*.list /etc/apt/sources.list.d/steam*.sources

# Ensure destination directory exists
sudo mkdir -p /usr/share/keyrings

# Download Valve's official keyring (this is the valid direct URL)
curl -fsSL https://repo.steampowered.com/steam/archive/stable/steam-archive-keyring.gpg | \
    sudo tee /usr/share/keyrings/steam-archive-keyring.gpg > /dev/null

sudo chmod 0644 /usr/share/keyrings/steam-archive-keyring.gpg

# Enable 32-bit architecture (required by Steam)
sudo dpkg --add-architecture i386

# Add modern DEB822 repository entry
sudo tee /etc/apt/sources.list.d/steam.sources > /dev/null <<EOF
Types: deb
URIs: https://repo.steampowered.com/steam
Suites: stable
Components: steam
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/steam-archive-keyring.gpg
EOF