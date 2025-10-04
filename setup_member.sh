#!/bin/bash
# Club Pi Member Setup Script
# Usage: sudo ./setup_member.sh <username>
# Example: sudo ./setup_member.sh tian

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

# 1. Add user to members group
if ! id -nG "$USER" | grep -qw "$GROUP"; then
    usermod -aG "$GROUP" "$USER"
fi

# 2. Set restricted shell
chsh -s /bin/rbash "$USER"

# 3. Create bin and work folders
mkdir -p "$USERHOME/bin" "$USERHOME/work"
chown -R "$USER:$GROUP" "$USERHOME/bin" "$USERHOME/work"

# 4. Add default allowed commands
for cmd in ls cat more less nano git python3 clear; do
    CMD_PATH=$(which $cmd 2>/dev/null)
    if [ -x "$CMD_PATH" ]; then
        ln -sf "$CMD_PATH" "$USERHOME/bin/$cmd"
        chown "$USER:$GROUP" "$USERHOME/bin/$cmd"
        chmod 755 "$USERHOME/bin/$cmd"
    fi
 done

# 5. Ensure .bash_profile exists
if [ ! -f "$USERHOME/.bash_profile" ]; then
    touch "$USERHOME/.bash_profile"
    chown "$USER:$GROUP" "$USERHOME/.bash_profile"
fi

# Configure PATH and auto-cd to work folder
grep -q 'PATH=$HOME/bin' "$USERHOME/.bash_profile" || echo 'PATH=$HOME/bin' >> "$USERHOME/.bash_profile"
grep -q 'cd ~/work' "$USERHOME/.bash_profile" || echo 'cd ~/work' >> "$USERHOME/.bash_profile"
chown "$USER:$GROUP" "$USERHOME/.bash_profile"

# 6. Cleanup test files
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

echo "User $USER setup complete. Workspace: $USERHOME/work"
