#!/bin/bash
# Club Pi Boot Setup Script (Simple Version)
# Usage: sudo ./clubpi_boot_setup.sh

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "🚀 Starting Club Pi boot setup..."

# --- 1. Update & Upgrade ---
apt update && apt upgrade -y

# --- 2. Install Git ---
apt install git -y

# --- 3. Create members group ---
getent group members >/dev/null || groupadd members

#-----4.install member setup-------
curl -o ~/setup_member.sh https://raw.githubusercontent.com/denmark-hc/clubpi/main/setup_member.shchmod +x ~/setup_member.sh

echo "✅ Club Pi boot setup complete."
echo "Default site available at: http://clubpi.local"
