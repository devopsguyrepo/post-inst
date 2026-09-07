#!/usr/bin/env bash
#
# modules/security-firewall.sh - Configure and Enable UFW
#

set -euo pipefail

log_info()    { echo -e "\e[34m[INFO]\e[0m $1"; }
log_success() { echo -e "\e[32m[OK]\e[0m $1"; }

log_info "Configuring UFW Firewall rules..."

# Ensure UFW is installed
if ! command -v ufw &>/dev/null; then
    sudo apt install -y ufw
fi

# Reset UFW to a clean state (optional, prevents duplicate rules)
sudo ufw --force reset

# Set default policies: Block all incoming, allow all outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# --------------------------------------------
# Custom Rules & Open Ports
# --------------------------------------------

# Allow local SSH (limit connection rate to prevent brute force attacks)
sudo ufw limit 22/tcp comment 'SSH with rate limiting'

# Allow local network services (adjust subnets/ports to your actual setup)
# Example: Local Web Server / Micro-services
# sudo ufw allow from 192.168.1.0/24 to any port 80,443 proto tcp comment 'Local Web Services'

# Example: Home Assistant / Specific Service Port
# sudo ufw allow 8123/tcp comment 'Home Assistant UI'

# Enable logging (medium level records blocked packets)
sudo ufw logging on

# Enable firewall service and ensure it runs on boot
sudo ufw --force enable
sudo systemctl enable ufw

log_success "UFW firewall configured and activated!"