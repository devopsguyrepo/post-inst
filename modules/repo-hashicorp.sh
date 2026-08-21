#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Setting up HashiCorp repository..."

# Fetch key and add source list
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo chmod 0644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null <<EOF
deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main
EOF