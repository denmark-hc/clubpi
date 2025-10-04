#!/bin/bash
# Club Pi Member Setup Script (Safe cd + rbash)
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
WORKDIR="$USERHOME/work"
PUBLICDIR="$WORKDIR/public"

# 1. Add user if it does not exist
id "$USER" &>/dev/null || adduser --gecos "" "$USER"

# 2. Add user to members group
usermod -aG "$GROUP" "$USER"

# 3. Set restricted shell
chsh -s /bin/rbash "$USER"

# 4. Create bin and work folders
mkdir -p "$USERHOME/bin" "$PUBLICDIR"
chown -R "$USER:$GROUP" "$USERHOME/bin" "$WORKDIR"

# 5. Add default allowed commands
for cmd in ls cat more less nano git python3 clear mkdir touch cd; do
    CMD_PATH=$(which $cmd 2>/dev/null)
    if [ -x "$CMD_PATH" ]; then
        ln -sf "$CMD_PATH" "$USERHOME/bin/$cmd"
        chown "$USER:$GROUP" "$USERHOME/bin/$cmd"
        chmod 755 "$USERHOME/bin/$cmd"
    fi
done

# 6. Configure PATH, safe cd, and start in home
BASH_PROFILE="$USERHOME/.bash_profile"
touch "$BASH_PROFILE"
chown "$USER:$GROUP" "$BASH_PROFILE"

grep -q 'PATH=$HOME/bin' "$BASH_PROFILE" || echo 'PATH=$HOME/bin:$PATH' >> "$BASH_PROFILE"

# Safe cd function
grep -q 'cd() {' "$BASH_PROFILE" || cat << 'EOF' >> "$BASH_PROFILE"

cd() {
    # Resolve target path
    TARGET=$(realpath "$1" 2>/dev/null || echo "$HOME")
    HOME_DIR="$HOME"
    if [[ "$TARGET" == "$HOME_DIR"* ]]; then
        builtin cd "$TARGET"
    else
        echo "Access denied: Can only cd inside your home folder."
    fi
}

# Start in home folder
cd $HOME
EOF

chown "$USER:$GROUP" "$BASH_PROFILE"

# 7. Create symlink for convenience
ln -s "$WORKDIR" "$USERHOME/site" 2>/dev/null
chown -h "$USER:$GROUP" "$USERHOME/site"

# 8. Cleanup test files
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

echo "User $USER setup complete."
echo "Home folder: $USERHOME"
echo "Workspace folder: $WORKDIR"
echo "Public folder: $PUBLICDIR"
echo "Leaders must add a Caddy entry to serve this user's public folder."
