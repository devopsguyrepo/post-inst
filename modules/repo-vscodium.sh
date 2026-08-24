#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up VSCodium repository..."

# Download and dearmor GPG key
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg status=none

# Set explicit read permissions so APT can read the key
sudo chmod 0644 /usr/share/keyrings/vscodium-archive-keyring.gpg

# Add VSCodium repository using modern DEB822 format (.sources)
# Uses inherited ${ARCH} variable if available, fallback to 'amd64 arm64'
sudo tee /etc/apt/sources.list.d/vscodium.sources > /dev/null <<EOF
Types: deb
URIs: https://download.vscodium.com/debs
Suites: vscodium
Components: main
Architectures: ${ARCH:-amd64 arm64}
Signed-By: /usr/share/keyrings/vscodium-archive-keyring.gpg 
EOF