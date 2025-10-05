#!/bin/bash
# Club Pi Member Setup Script (Folders + Optional Caddy Block)
# Usage: sudo ./setup_member.sh <username>

if [ "$EUID" -ne 0 ]; then
  echo "Run as root."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USER=$1
GROUP=members
USERHOME="/home/$USER"

# --- 1. Add user to members group ---
if ! id -nG "$USER" | grep -qw "$GROUP"; then
    usermod -aG "$GROUP" "$USER"
fi

# --- 2. Create work and public folders ---
mkdir -p "$USERHOME/work/public"
chown -R "$USER:$GROUP" "$USERHOME/work"

# --- 3. Symlink for convenience ---
ln -sf "$USERHOME/work" "$USERHOME/site"
chown -h "$USER:$GROUP" "$USERHOME/site"

# --- 4. Optional: Add basic Caddy block (leader can adjust Unix socket) ---
CADDYFILE="/etc/caddy/Caddyfile"
SOCKET="/home/$USER/.caddy/$USER.sock"
sudo mkdir -p "/home/$USER/.caddy"
sudo touch "$SOCKET"
sudo chown "$USER:$GROUP" "$SOCKET"

MEMBER_BLOCK="http://$USER.clubpi.local {\n    bind unix//$SOCKET|777\n    root * $USERHOME/work/public\n    file_server\n}\n"

if ! grep -q "http://$USER.clubpi.local" "$CADDYFILE" 2>/dev/null; then
    echo -e "$MEMBER_BLOCK" >> "$CADDYFILE"
    systemctl reload caddy
    echo "✅ Added Caddy block for $USER at http://$USER.clubpi.local"
fi

echo "✅ User $USER setup complete!"
echo "Workspace: $USERHOME/work"
echo "Public folder served via Caddy: $USERHOME/work/public"
echo "Symlink for convenience: $USERHOME/site"
echo "Members can safely create folders and files inside their home."
