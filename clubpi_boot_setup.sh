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

# --- 4. Install Caddy ---
if ! command -v caddy &>/dev/null; then
    apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | bash
    apt install caddy -y
fi

# --- 5. Setup default Caddyfile ---
mkdir -p /etc/caddy
cat >/etc/caddy/Caddyfile <<'EOF'
# Default site
http://clubpi.local {
    root * /var/www/html
    file_server
}
EOF
mkdir -p /var/www/html
echo "<h1>Welcome to Club Pi Leader</h1>" > /var/www/html/index.html

# --- 6. Enable & restart Caddy ---
systemctl enable caddy
systemctl restart caddy

echo "✅ Club Pi boot setup complete."
echo "Default site available at: http://clubpi.local"
