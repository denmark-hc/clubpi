#!/bin/bash
# Club Pi Member Setup Script (Old Style)
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

# 1. Add user if it does not exist
id "$USER" &>/dev/null || adduser --gecos "" "$USER"

# 2. Add user to members group
usermod -aG "$GROUP" "$USER"

# 3. Set restricted shell
chsh -s /bin/rbash "$USER"

# 4. Create bin and work folders
mkdir -p "$USERHOME/bin" "$WORKDIR/public"
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

# 6. Configure PATH and start in home
if [ ! -f "$USERHOME/.bash_profile" ]; then
    touch "$USERHOME/.bash_profile"
    chown "$USER:$GROUP" "$USERHOME/.bash_profile"
fi

grep -q 'PATH=$HOME/bin' "$USERHOME/.bash_profile" || echo 'PATH=$HOME/bin:$PATH' >> "$USERHOME/.bash_profile"
grep -q 'cd $HOME' "$USERHOME/.bash_profile" || echo 'cd $HOME' >> "$USERHOME/.bash_profile"
chown "$USER:$GROUP" "$USERHOME/.bash_profile"

# 7. Cleanup test files
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

echo "User $USER setup complete."
echo "Home folder: $USERHOME"
echo "Workspace folder: $WORKDIR"
echo "Public folder: $WORKDIR/public"
echo "Leaders must add a Caddy entry to serve this user's public folder."
