#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up VirtualBox repository..."

# Fetch ASCII key and dearmor it into binary format directly in /usr/share/keyrings
curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/oracle-virtualbox-2016.gpg > /dev/null

# Set explicit read permissions
sudo chmod 0644 /usr/share/keyrings/oracle-virtualbox-2016.gpg

# Detect Ubuntu underlying codename (e.g., noble for Mint 22 / Ubuntu 24.04)
UBUNTU_CODENAME=$(grep -oP 'UBUNTU_CODENAME=\K\w+' /etc/os-release || echo "noble")
ARCH=$(dpkg --print-architecture)

# Add repository using modern DEB822 format
sudo tee /etc/apt/sources.list.d/virtualbox.sources > /dev/null <<EOF
Types: deb
URIs: https://download.virtualbox.org/virtualbox/debian
Suites: ${UBUNTU_CODENAME}
Components: contrib
Architectures: ${ARCH}
Signed-By: /usr/share/keyrings/oracle-virtualbox-2016.gpg
EOF