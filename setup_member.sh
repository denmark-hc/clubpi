#!/bin/bash
# Club Pi Member Setup Script (Full Setup)
# Usage: sudo ./setup_member.sh <username>
# Example: sudo ./setup_member.sh mig

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

# 3. Create necessary folders
mkdir -p "$USERHOME/bin" "$USERHOME/work/public"
chown -R "$USER:$GROUP" "$USERHOME/bin" "$USERHOME/work"

# 4. Add default allowed commands
for cmd in ls cat more less nano git python3 mkdir touch clear pwd realpath bash; do
    CMD_PATH=$(which $cmd 2>/dev/null)
    if [ -x "$CMD_PATH" ]; then
        ln -sf "$CMD_PATH" "$USERHOME/bin/$cmd"
        chown "$USER:$GROUP" "$USERHOME/bin/$cmd"
        chmod 755 "$USERHOME/bin/$cmd"
    fi
done

# 5. Ensure .bash_profile and .bashrc exist
for file in .bash_profile .bashrc; do
    if [ ! -f "$USERHOME/$file" ]; then
        touch "$USERHOME/$file"
        chown "$USER:$GROUP" "$USERHOME/$file"
    fi
done

# 6. Configure PATH and add safe cd function in both files
for file in .bash_profile .bashrc; do
    grep -q 'PATH=$HOME/bin' "$USERHOME/$file" || echo 'PATH=$HOME/bin' >> "$USERHOME/$file"
    grep -q 'function cd()' "$USERHOME/$file" || cat >> "$USERHOME/$file" <<'EOF'
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
done

chown "$USER:$GROUP" "$USERHOME/.bash_profile" "$USERHOME/.bashrc"

# 7. Cleanup old test files
rm -f "$USERHOME"/test* 2>/dev/null
rm -f "$USERHOME"/*.tmp 2>/dev/null

# 8. Create symlink for convenience
ln -sf "$USERHOME/work" "$USERHOME/site"
chown -h "$USER:$GROUP" "$USERHOME/site"

echo "User $USER setup complete."
echo "Workspace: $USERHOME/work"
