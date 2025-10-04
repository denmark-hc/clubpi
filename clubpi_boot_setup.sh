#!/bin/bash
# Club Pi Boot Setup Script
# Usage: sudo ./clubpi_boot_setup.sh
# This script sets up the system for Club Pi, including Caddy and member management

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "Starting Club Pi boot setup..."

# --- 1. Update & Upgrade system ---
echo "Updating system..."
apt update && apt upgrade -y

# --- 2. Install Git ---
echo "Installing Git..."
apt install git -y

# --- 3. Create members group ---
echo "Creating 'members' group if it doesn't exist..."
getent group members >/dev/null || groupadd members

# --- 4. Install Caddy ---
echo "Installing Caddy..."
if ! command -v caddy &>/dev/null; then
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.sh' | bash
    apt install caddy -y
fi

# Enable and start Caddy
systemctl enable caddy
systemctl start caddy

# --- 5. Setup global Caddy include for members ---
CADDY_GLOBAL_FILE="/etc/caddy/Caddyfile"
echo "Setting up global Caddy include for member Caddyfiles..."
if [ ! -f "$CADDY_GLOBAL_FILE" ]; then
    touch "$CADDY_GLOBAL_FILE"
    chown root:root "$CADDY_GLOBAL_FILE"
    chmod 644 "$CADDY_GLOBAL_FILE"
fi

# Add import line if not present
grep -q '^import /home/\*/work/Caddyfile' "$CADDY_GLOBAL_FILE" || \
    echo "import /home/*/work/Caddyfile" >> "$CADDY_GLOBAL_FILE"

# Reload Caddy to apply any existing member Caddyfiles
systemctl reload caddy

# --- 6. Create default directories for existing members ---
echo "Ensuring existing members have work folders..."
for user in $(getent passwd | awk -F: '$4 == 1000 {print $1}'); do
    USERHOME="/home/$user"
    WORKDIR="$USERHOME/work"
    mkdir -p "$WORKDIR/public" "$USERHOME/bin"
    chown -R "$user:members" "$WORKDIR" "$USERHOME/bin"

    # Create Caddyfile for the member if missing
    if [ ! -f "$WORKDIR/Caddyfile" ]; then
        cat <<EOL > "$WORKDIR/Caddyfile"
http://clubpi.local/$user {
    root * $WORKDIR/public
    file_server
}
EOL
        chown "$user:members" "$WORKDIR/Caddyfile"
        chmod 644 "$WORKDIR/Caddyfile"
    fi
done

# --- 7. Cleanup temporary files ---
echo "Cleaning up test and temp files..."
for user in $(getent passwd | awk -F: '$4 == 1000 {print $1}'); do
    rm -f "/home/$user"/test* 2>/dev/null
    rm -f "/home/$user"/*.tmp 2>/dev/null
done

echo "Club Pi boot setup complete!"
echo "Caddy is running and member sites are automatically included."
echo "Members should place files in ~/work/public and edit ~/work/Caddyfile for their own site."
