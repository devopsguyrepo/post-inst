#!/usr/bin/env bash
#
# post-inst.sh - Linux Mint Automated Restoration Script
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

# 1. Create keyrings directories once upfront
sudo install -m 0755 -d /etc/apt/keyrings
sudo install -m 0755 -d /usr/share/keyrings

# 2. Export environment variables so child modules can use them directly
export ARCH="$(dpkg --print-architecture)"
export UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$UBUNTU_CODENAME}")"

# --------------------------------------------
# 2. Custom Repositories & PPAs
# --------------------------------------------
MODULES_DIR="$SCRIPT_DIR/modules"

PPA_REPOS=(
    ppa:mozillateam/ppa
)

# Add PPAs if array is not empty
if [ ${#PPA_REPOS[@]} -gt 0 ]; then
    log_info "Adding Launchpad PPAs..."
    sudo add-apt-repository -y "${PPA_REPOS[@]}"
fi

# Execute Third-Party Repository Modules
if [ -d "$MODULES_DIR" ]; then
    log_info "Executing third-party repository modules in $MODULES_DIR..."
    for module in "$MODULES_DIR"/*.sh; do
        # Prevent failure if no .sh files match the glob
        [ -e "$module" ] || continue
        
        log_info "Running module: $(basename "$module")"
        bash "$module"
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
APT_PACKAGES=(
    curl
    git
    build-essential
    htop
    vlc
    vim
)

log_info "Installing APT packages..."
sudo apt install -y "${APT_PACKAGES[@]}"

# --------------------------------------------
# 6. Flatpaks
# --------------------------------------------
FLATPAKS=(
    com.spotify.Client
    org.signal.Signal
)

if command -v flatpak &> /dev/null; then
    log_info "Installing Flatpak applications..."
    flatpak install -y flathub "${FLATPAKS[@]}"
fi

# --------------------------------------------
# 7. NetworkManager MAC Address Randomization
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
# 8. Cleanup
# --------------------------------------------
log_info "Cleaning up leftover packages..."
sudo apt autoremove -y && sudo apt clean

log_success "Restoration complete! Please restart your machine."