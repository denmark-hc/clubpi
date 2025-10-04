#!/bin/bash
# Club Pi boot setup script
# Run as root or via systemd on boot

echo "[Club Pi] Starting boot setup..."

# 1. Update & upgrade system
echo "[Club Pi] Updating and upgrading system..."
apt update && apt upgrade -y

# 2. Install Git
echo "[Club Pi] Installing Git..."
apt install -y git

# 3. Create members group if it doesn't exist
GROUP=members
if ! getent group $GROUP > /dev/null; then
    groupadd $GROUP
    echo "[Club Pi] Group '$GROUP' created."
else
    echo "[Club Pi] Group '$GROUP' already exists."
fi

# 4. Install Caddy
echo "[Club Pi] Installing Caddy..."
# Add Caddy repository
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

echo "[Club Pi] Boot setup complete!"



Make 
