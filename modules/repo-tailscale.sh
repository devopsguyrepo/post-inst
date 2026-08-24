#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up Tailscale repository..."

# Fetch GPG key
sudo curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_CODENAME}.noarmor.gpg" \
    -o /usr/share/keyrings/tailscale-archive-keyring.gpg

# Set explicit read permissions
sudo chmod 0644 /usr/share/keyrings/tailscale-archive-keyring.gpg

# Add repository using DEB822 format
sudo tee /etc/apt/sources.list.d/tailscale.sources > /dev/null <<EOF
Types: deb
URIs: https://pkgs.tailscale.com/stable/ubuntu
Suites: ${UBUNTU_CODENAME}
Components: main
Architectures: ${ARCH}
Signed-By: /usr/share/keyrings/tailscale-archive-keyring.gpg
EOF