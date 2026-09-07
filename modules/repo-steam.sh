#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up Steam repository..."

# Purge pre-existing or auto-generated Steam source files to avoid collisions
sudo rm -f /etc/apt/sources.list.d/steam*.list /etc/apt/sources.list.d/steam*.sources

# Ensure target directory exists
sudo mkdir -p /usr/share/keyrings

# Download updated Valve keyring URL
curl -fsSL https://repo.steampowered.com/steam/gpg | \
    gpg --dearmor --yes | \
    sudo tee /usr/share/keyrings/steam-archive-keyring.gpg > /dev/null

sudo chmod 0644 /usr/share/keyrings/steam-archive-keyring.gpg

# Enable 32-bit architecture required by Steam
sudo dpkg --add-architecture i386

# Add clean DEB822 entry
sudo tee /etc/apt/sources.list.d/steam.sources > /dev/null <<EOF
Types: deb
URIs: https://repo.steampowered.com/steam
Suites: stable
Components: steam
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/steam-archive-keyring.gpg
EOF