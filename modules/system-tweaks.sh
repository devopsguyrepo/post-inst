#!/usr/bin/env bash
#
# modules/system-tweaks.sh - Hardware, Power & Performance Optimization
#

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Applying system hardware and performance tweaks..."

# --------------------------------------------
# 1. SSD Weekly TRIM
# --------------------------------------------
if systemctl list-unit-files | grep -q "fstrim.timer"; then
    echo "   -> Enabling weekly SSD TRIM timer..."
    sudo systemctl enable --now fstrim.timer
fi

# --------------------------------------------
# 2. Disable Bluetooth at Boot
# --------------------------------------------
if systemctl list-unit-files | grep -q "bluetooth.service"; then
    echo "   -> Disabling Bluetooth auto-start at boot..."
    sudo systemctl disable bluetooth.service
fi

# --------------------------------------------
# 3. Hybrid Graphics Detection & Configuration
# --------------------------------------------
# Check for both Intel/AMD integrated GPU and NVIDIA discrete GPU
if lspci | grep -i vga | grep -iq "nvidia\|3D controller" || lspci | grep -iq "nvidia"; then
    if command -v prime-select &>/dev/null; then
        echo "   -> Hybrid graphics detected! Setting NVIDIA profile to 'on-demand'..."
        sudo prime-select on-demand
    fi
fi

# --------------------------------------------
# 4. Disable ModemManager (Cellular modem daemon)
# --------------------------------------------
if systemctl list-unit-files | grep -q "ModemManager.service"; then
    echo "   -> Disabling ModemManager (unneeded cellular service)..."
    sudo systemctl disable ModemManager.service
fi

# --------------------------------------------
# 5. Increase System File Watcher Limits (for VSCodium/IDE compatibility)
# --------------------------------------------
echo "   -> Optimizing inotify file watch limits..."
sudo tee /etc/sysctl.d/60-max-user-watches.conf > /dev/null << 'EOF'
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
EOF
sudo sysctl --system > /dev/null

# --------------------------------------------
# 6. Restrict systemd Journal Log Size (Max 500MB)
# --------------------------------------------
echo "   -> Capping systemd log storage to 500MB..."
sudo journalctl --vacuum-size=500M > /dev/null
sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=500M/' /etc/systemd/journald.conf

echo -e "\e[32m[OK]\e[0m System tweaks successfully applied!"

# --------------------------------------------
# 7. Reducing swappiness and installing ZRAM
# --------------------------------------------
# Reduce swappiness
sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null << 'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF
sudo sysctl --system

# Install and configure ZRAM
if sudo apt install -y zram-tools; then
    sudo tee /etc/default/zramswap > /dev/null << 'EOF'
PERCENTED=50
ALGORITHM=zstd
EOF
    sudo systemctl restart zramswap
fi