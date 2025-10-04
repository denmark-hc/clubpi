#!/bin/bash
# Club Pi Member Setup Script (Caddy in ~/work)
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

# 1. Add user if not exist
id "$USER" &>/dev/null || adduser --gecos "" "$USER"

# 2. Add user to members group
usermod -aG "$GROUP" "$USER"

# 3. Set restricted shell
chsh -s /bin/rbash "$USER"

# 4. Create necessary folders
mkdir -p "$USERHOME/bin" "$WORKDIR/public"
chown -R "$USER:$GROUP" "$USERHOME/bin" "$WORKDIR"

# 5. Create ~/site symlink to public for convenience
ln -sf "$WORKDIR/public" "$USERHOME/site"
chown -h "$USER:$GROUP" "$USERHOME/site"

# 6. Add default allowed commands
for cmd in ls cat more less nano git python3 clear mkdir touch; do
    CMD_PATH=$(which $cmd 2>/dev/null)
    if [ -x "$CMD_PATH" ]; then
        ln -sf "$CMD_PATH" "$USERHOME/bin/$cmd"
        chown "$USER:$GROUP" "$USERHOME/bin/$cmd"
        chmod 755 "$USERHOME/bin/$cmd"
    fi
done

# 7. Create safe cd script
cat <<'EOL' > "$USERHOME/bin/cd_safe"
#!/bin/bash
TARGET="$1"
HOME_DIR="$HOME"
DEST=$(realpath "$HOME_DIR/$TARGET" 2>/dev/null)
if [[ "$DEST" == "$HOME_DIR"* ]]; then
    cd "$DEST" || return
    pwd
else
    echo "Restricted: You can only navigate inside your home directory"
fi
EOL

chmod +x "$USERHOME/bin/cd_safe"
chown "$USER:$GROUP" "$USERHOME/bin/cd_safe"
ln -sf "$USERHOME/bin/cd_safe" "$USERHOME/bin/cd"
chown -h "$USER:$GROUP" "$USERHOME/bin/cd"

# 8. Configure PATH and start in home
if [ ! -f "$USERHOME/.bash_profile" ]; then
    touch "$USERHOME/.bash_profile"
    chown "$USER:$GROUP" "$USERHOME/.bash_profile"
fi

grep -q 'PATH=$HOME/bin' "$USERHOME/.bash_profile" || echo 'PATH=$HOME/bin:$PATH' >> "$USERHOME/.bash_profile"
grep -q 'cd $HOME' "$USERHOME/.bash_profile" || echo 'cd $HOME' >> "$USERHOME/.bash_profile"
chown "$USER:$GROUP" "$USERHOME/.bash_profile"

# 9. Create member Caddyfile inside ~/work
cat <<EOL > "$WORKDIR/Caddyfile"
http://clubpi.local/$USER {
    root * $WORKDIR/public
    file_server
}
EOL
chown "$USER:$GROUP" "$WORKDIR/Caddyfile"
chmod 644 "$WORKDIR/Caddyfile"

# 10. Cleanup
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

echo "User $USER setup complete."
echo "Home: $USERHOME"
echo "Workspace: $WORKDIR"
echo "Public folder: $WORKDIR/public"
echo "Caddyfile: $WORKDIR/Caddyfile"
echo "Use 'cd public' to navigate safely inside your public folder."
