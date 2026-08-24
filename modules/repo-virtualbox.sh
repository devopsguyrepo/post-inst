#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up VirtualBox repository..."

# Fetch GPG key directly to /usr/share/keyrings
sudo curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc \
    -o /usr/share/keyrings/oracle-virtualbox-2016.gpg

# Set explicit read permissions
sudo chmod 0644 /usr/share/keyrings/oracle-virtualbox-2016.gpg

# Add repository using modern DEB822 format
sudo tee /etc/apt/sources.list.d/virtualbox.sources > /dev/null <<EOF
Types: deb
URIs: https://download.virtualbox.org/virtualbox/debian
Suites: ${UBUNTU_CODENAME}
Components: contrib
Architectures: ${ARCH}
Signed-By: /usr/share/keyrings/oracle-virtualbox-2016.gpg
EOF