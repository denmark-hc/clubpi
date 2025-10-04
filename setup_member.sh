#!/bin/bash
# Club Pi Member Setup Script (Minimal & Safe)
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

# 1. Add user to members group
if ! id -nG "$USER" | grep -qw "$GROUP"; then
    usermod -aG "$GROUP" "$USER"
fi

# 2. Set restricted shell
chsh -s /bin/rbash "$USER"

# 3. Create work folder
mkdir -p "$USERHOME/work"
chown -R "$USER:$GROUP" "$USERHOME/work"

# 4. Ensure .bash_profile exists
if [ ! -f "$USERHOME/.bash_profile" ]; then
    touch "$USERHOME/.bash_profile"
    chown "$USER:$GROUP" "$USERHOME/.bash_profile"
fi

# 5. Safe cd inside home
grep -q 'function cd()' "$USERHOME/.bash_profile" || cat >> "$USERHOME/.bash_profile" <<'EOF'
function cd() {
  if [ -z "$1" ]; then
    builtin cd "$HOME"
  else
    TARGET=$(realpath -m "$1")
    if [[ "$TARGET" == "$HOME"* && -d "$TARGET" ]]; then
      builtin cd "$TARGET"
    else
      echo "Restricted: cannot cd outside home."
    fi
  fi
}
cd $HOME
EOF
chown "$USER:$GROUP" "$USERHOME/.bash_profile"

# 6. Cleanup test files
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

# 7. Symlink for convenience
ln -sf "$USERHOME/work" "$USERHOME/site"
chown -h "$USER:$GROUP" "$USERHOME/site"

echo "✅ User $USER setup complete!"
echo "Workspace: $USERHOME/work"
echo "Members can create folders/files inside their home, but cannot access system files."
