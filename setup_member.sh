#!/bin/bash
# Club Pi Member Setup Script (Updated)
# Usage: sudo ./setup_member.sh <username>
# Example: sudo ./setup_member.sh oscar

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

# 3. Create bin, work, and public folders
mkdir -p "$USERHOME/bin" "$USERHOME/work/public"
chown -R "$USER:$GROUP" "$USERHOME/bin" "$USERHOME/work"

# 4. Add default allowed commands
for cmd in ls cat more less nano git python3 mkdir touch clear pwd; do
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

# 6. Configure PATH and safe cd inside home
grep -q 'PATH=$HOME/bin' "$USERHOME/.bash_profile" || echo 'PATH=$HOME/bin' >> "$USERHOME/.bash_profile"

# Custom function to allow cd anywhere inside home
grep -q 'function cd()' "$USERHOME/.bash_profile" || cat >> "$USERHOME/.bash_profile" <<'EOF'
function cd() {
  if [ -z "$1" ]; then
    builtin cd "$HOME"
  else
    TARGET="$HOME/$1"
    if [[ "$TARGET" == "$HOME"* && -d "$TARGET" ]]; then
      builtin cd "$TARGET"
    else
      echo "Restricted: cannot cd outside home."
    fi
  fi
}
EOF

# Auto-start in home directory
grep -q 'cd $HOME' "$USERHOME/.bash_profile" || echo 'cd $HOME' >> "$USERHOME/.bash_profile"

chown "$USER:$GROUP" "$USERHOME/.bash_profile"

# 7. Cleanup test files
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

# 8. Create convenient symlink to work
ln -sf "$USERHOME/work" "$USERHOME/site"
chown -h "$USER:$GROUP" "$USERHOME/site"

echo "User $USER setup complete. Workspace: $USERHOME/work"
