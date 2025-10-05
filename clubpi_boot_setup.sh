#!/bin/bash
# Club Pi Boot Setup Script (Updated with Unix Socket)
# Usage: sudo ./clubpi_boot_setup.sh

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "Starting Club Pi boot setup..."

# --- 1. Update & Upgrade ---
apt update && apt upgrade -y

# --- 2. Install Git ---
apt install git -y

# --- 3. Create members group ---
getent group members >/dev/null || groupadd members

# --- 4. Install Caddy ---
if ! command -v caddy &>/dev/null; then
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | bash
    apt install caddy -y
fi

# Enable and start Caddy
systemctl enable caddy
systemctl start caddy

# --- 5. Configure Unix Domain Socket for Caddy Admin ---
CADDY_ADMIN_SOCKET="/home/leader/caddy-admin.sock"

# Backup existing Caddyfile if exists
[ -f /etc/caddy/Caddyfile ] && cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak

# Add global admin block if not already present
grep -q 'admin unix' /etc/caddy/Caddyfile || cat >> /etc/caddy/Caddyfile <<EOF
{
    admin unix//$CADDY_ADMIN_SOCKET
}
EOF

# Ensure proper permissions
touch "$CADDY_ADMIN_SOCKET"
chown leader:leader "$CADDY_ADMIN_SOCKET"
chmod 660 "$CADDY_ADMIN_SOCKET"

# Reload Caddy to apply new configuration
systemctl reload caddy

echo "Club Pi boot setup complete."
echo "Caddy is installed and running."
echo "Admin Unix socket created at $CADDY_ADMIN_SOCKET for leader."
echo "Leaders can now manage Caddy via this socket."
