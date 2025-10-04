#!/bin/bash
# Club Pi Member Setup Script (Folders Only)
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

# Add user to members group if not already
if ! id -nG "$USER" | grep -qw "$GROUP"; then
    usermod -aG "$GROUP" "$USER"
fi

# Create work folders inside home
mkdir -p "$USERHOME/work"
chown -R "$USER:$GROUP" "$USERHOME/work"

# Create a public folder inside work (optional for future Caddy use)
mkdir -p "$USERHOME/work/public"
chown -R "$USER:$GROUP" "$USERHOME/work/public"

# Symlink for convenience
ln -sf "$USERHOME/work" "$USERHOME/site"
chown -h "$USER:$GROUP" "$USERHOME/site"

echo "✅ User $USER folders created!"
echo "Workspace: $USERHOME/work"
echo "Members can create files and folders inside their home safely."
