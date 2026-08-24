#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up NextDNS repository..."

# Fetch GPG key
sudo curl -fsSL https://repo.nextdns.io/nextdns.gpg \
    -o /usr/share/keyrings/nextdns-archive-keyring.gpg

# Set explicit read permissions
sudo chmod 0644 /usr/share/keyrings/nextdns-archive-keyring.gpg

# Add repository using DEB822 format
sudo tee /etc/apt/sources.list.d/nextdns.sources > /dev/null <<EOF
Types: deb
URIs: https://repo.nextdns.io/deb
Suites: stable
Components: main
Architectures: ${ARCH}
Signed-By: /usr/share/keyrings/nextdns-archive-keyring.gpg
EOF