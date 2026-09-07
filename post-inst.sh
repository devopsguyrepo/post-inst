#!/usr/bin/env bash
#
# post-inst.sh - Linux Mint / Debian-based Automated Restoration Script
#
# Usage:
#     chmod +x post-inst.sh
#     ./post-inst.sh
#

# Stop execution if any command fails or if an unset variable is used
set -euo pipefail

# Visual feedback functions
log_info()    { echo -e "\e[34m[INFO]\e[0m $1"; }
log_success() { echo -e "\e[32m[OK]\e[0m $1"; }
log_error()   { echo -e "\e[31m[ERROR]\e[0m $1"; }

# --------------------------------------------
# Pre-checks & Sudo Keep-Alive
# --------------------------------------------
if [[ $EUID -eq 0 ]]; then
   log_error "Do not run this script with sudo directly. It will prompt for sudo when needed."
   exit 1
fi

log_info "Starting post-installation process..."
sudo -v # Refresh sudo privilege timer upfront

# Keep sudo timestamp updated during script execution
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_LOOP_PID=$!

# Ensure background processes are cleaned up on exit
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true' EXIT

# --------------------------------------------
# 1. System Environment & Directory Preparation
# --------------------------------------------
log_info "Preparing system directories and environment..."

# Resolve absolute path to script folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Create keyrings directories once upfront
sudo install -m 0755 -d /etc/apt/keyrings
sudo install -m 0755 -d /usr/share/keyrings

# Export environment variables for child modules
# Sources os-release safely; defaults to UBUNTU_CODENAME, falling back to VERSION_CODENAME for Debian
source /etc/os-release
export ARCH="$(dpkg --print-architecture)"
export UBUNTU_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"

# --------------------------------------------
# 2. Custom Repositories & PPAs
# --------------------------------------------
if [ -d "$MODULES_DIR" ]; then
    log_info "Executing repository setup modules in $MODULES_DIR..."
    for module in "$MODULES_DIR"/repo-*.sh; do
        # Prevent failure if no repo .sh files match the glob
        [ -e "$module" ] || continue
        
        log_info "Running repository module: $(basename "$module")"
        ( cd "$SCRIPT_DIR" && bash "$module" )
    done
else
    log_error "Modules directory not found at $MODULES_DIR!"
    exit 1
fi

# --------------------------------------------
# 3. System Updates
# --------------------------------------------
log_info "Updating package lists and upgrading system..."
sudo apt update && sudo apt dist-upgrade -y

# --------------------------------------------
# 4. Browser Swap (Firefox Standard -> ESR)
# --------------------------------------------
log_info "Swapping Firefox Standard for Firefox ESR..."

# Prevent APT from pulling standard Firefox updates
sudo tee /etc/apt/preferences.d/mozilla-firefox-esr > /dev/null << 'EOF'
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

# Purge stock Firefox and install ESR
sudo apt purge -y firefox firefox-locale-* 2>/dev/null || true
sudo apt install -y firefox-esr

# --------------------------------------------
# 5. Native Packages (APT)
# --------------------------------------------
if [ -f "$SCRIPT_DIR/apt_apps.txt" ]; then
    log_info "Installing user APT packages..."
    
    # Pre-accept Microsoft TrueType Core Fonts EULA for automated installs
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
    echo "ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note" | sudo debconf-set-selections

    # Strip full & inline comments
    mapfile -t APT_APPS < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$SCRIPT_DIR/apt_apps.txt")
    
    if [ ${#APT_APPS[@]} -gt 0 ]; then
        sudo DEBIAN_FRONTEND=noninteractive apt install -y "${APT_APPS[@]}"
        log_success "APT packages restored!"
    fi
fi

# --------------------------------------------
# 6. Flatpaks
# --------------------------------------------
if [ -f "$SCRIPT_DIR/flatpaks.txt" ]; then
    log_info "Installing Flatpak applications..."

    # Ensure Flathub remote is added system-wide
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Parse flatpaks.txt (removing comments and blank lines)
    mapfile -t FLATPAK_APPS < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$SCRIPT_DIR/flatpaks.txt")

    if [ ${#FLATPAK_APPS[@]} -gt 0 ]; then
        # Use sudo and -y for hands-free system deployment
        sudo flatpak install -y flathub "${FLATPAK_APPS[@]}"
        log_success "Flatpak applications restored!"
    fi
fi

# --------------------------------------------
# 7. Post-Install User Group Adjustments
# --------------------------------------------
if command -v docker &>/dev/null; then
    log_info "Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
fi

# --------------------------------------------
# 8. Restore Local Dotfiles (GNU Stow)
# --------------------------------------------
if [ -f "$MODULES_DIR/dotfiles.sh" ]; then
    log_info "Executing dotfiles restoration module..."
    ( cd "$SCRIPT_DIR" && bash "$MODULES_DIR/dotfiles.sh" )
fi

# --------------------------------------------
# 9. Provision Network Services (NextDNS & Tailscale)
# --------------------------------------------
if [ -f "$MODULES_DIR/net-provision.sh" ]; then
    log_info "Executing network provisioning module..."
    ( cd "$SCRIPT_DIR" && bash "$MODULES_DIR/net-provision.sh" )
fi

# --------------------------------------------
# 10. Hardware, Kernel & System Performance Tweaks
# --------------------------------------------
if [ -f "$MODULES_DIR/system-tweaks.sh" ]; then
    log_info "Executing system performance tweaks..."
    ( cd "$SCRIPT_DIR" && bash "$MODULES_DIR/system-tweaks.sh" )
fi

# --------------------------------------------
# 11. Enable Power Management (TLP)
# --------------------------------------------
if [ -f "$MODULES_DIR/tlp-config.sh" ]; then
    log_info "Deploying custom TLP drop-in configuration..."
    ( cd "$SCRIPT_DIR" && bash "$MODULES_DIR/tlp-config.sh" )
elif command -v tlp &>/dev/null; then
    log_info "Enabling default TLP power management service..."
    sudo systemctl enable --now tlp
fi

# --------------------------------------------
# 12. NetworkManager MAC Address Randomization
# --------------------------------------------
log_info "Configuring MAC address randomization..."

sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null << 'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

sudo systemctl restart NetworkManager

# --------------------------------------------
# 13. Enable Security & Firewall Rules (UFW)
# --------------------------------------------
if [ -f "$MODULES_DIR/security-firewall.sh" ]; then
    log_info "Executing firewall configuration module..."
    ( cd "$SCRIPT_DIR" && bash "$MODULES_DIR/security-firewall.sh" )
fi

# --------------------------------------------
# 14. Cleanup
# --------------------------------------------
log_info "Cleaning up leftover packages..."
sudo apt autoremove -y && sudo apt clean

log_success "Restoration complete! Please restart your machine."