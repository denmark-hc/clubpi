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
apt install -y git

# --- 3. Create members group ---
getent group members >/dev/null || groupadd members

# --- 4. Install member setup script ---
# --- 4. Install member setup script ---
curl -o /home/$SUDO_USER/setup_member.sh https://raw.githubusercontent.com/denmark-hc/clubpi/main/setup_member.sh
chmod +x /home/$SUDO_USER/setup_member.sh
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/setup_member.sh


echo "✅ Club Pi boot setup complete."
echo "Member setup script saved at: ~/setup_member.sh"
