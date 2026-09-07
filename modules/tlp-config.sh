#!/usr/bin/env bash
#
# modules/tlp-config.sh - Deploy custom TLP power & battery settings
#

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Applying custom TLP power and battery threshold configurations..."

# Ensure TLP directory exists
sudo mkdir -p /etc/tlp.d

# Write active custom settings to drop-in file 01-custom.conf
sudo tee /etc/tlp.d/01-custom.conf > /dev/null << 'EOF'
# ------------------------------------------------------------------------------
# Custom TLP Drop-in Configuration for Intel i7-7500U Laptop
# ------------------------------------------------------------------------------

# CPU Operation & Governor Mode
CPU_DRIVER_OPMODE_ON_AC=active
CPU_DRIVER_OPMODE_ON_BAT=active
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Intel Energy Performance Policy (EPP)
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# Max Performance Cap (Thermal management)
CPU_MAX_PERF_ON_AC=95
CPU_MAX_PERF_ON_BAT=90

# Turbo Boost & Dynamic I/O Boost
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=1

# Platform Profile
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=balanced

# Battery Care Thresholds (Preserve battery health)
START_CHARGE_THRESH_BAT0=50
STOP_CHARGE_THRESH_BAT0=81
RESTORE_THRESHOLDS_ON_BAT=0
EOF

# Restart TLP to apply new settings immediately
if command -v tlp &>/dev/null; then
    echo "   -> Restarting TLP service..."
    sudo tlp start > /dev/null
fi

echo -e "\e[32m[OK]\e[0m TLP configuration applied successfully!"