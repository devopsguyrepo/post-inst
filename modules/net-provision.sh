#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34m[MODULE]\e[0m Provisioning network services..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CREDS_FILE="$SCRIPT_DIR/.credentials"

# Source credentials file if present
if [ -f "$CREDS_FILE" ]; then
    # Filter out comments and export key-value pairs
    set -a
    # shellcheck disable=SC1090
    source <(grep -v '^#' "$CREDS_FILE" | grep -v '^[[:space:]]*$')
    set +a
fi

# 1. Setup NextDNS
if command -v nextdns &>/dev/null; then
    if [ -n "${NEXTDNS_PROFILE_ID:-}" ]; then
        echo "   -> Installing NextDNS daemon with Profile ID: $NEXTDNS_PROFILE_ID..."
        sudo nextdns install -profile "$NEXTDNS_PROFILE_ID" -report-client-info -auto-activate
    else
        echo -e "\e[33m[WARN]\e[0m NEXTDNS_PROFILE_ID not set in .credentials. Run 'sudo nextdns setup' manually."
    fi
fi

# 2. Enable Tailscale Daemon
if command -v tailscale &>/dev/null; then
    echo "   -> Enabling Tailscale daemon..."
    sudo systemctl enable --now tailscaled
    echo -e "\e[32m[OK]\e[0m Tailscale ready! Run 'sudo tailscale up' after reboot."
fi