#!/bin/bash
# Club Pi Member Setup Script
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

echo "👤 Setting up member: $USER"

# 1. Add user if missing
if ! id "$USER" &>/dev/null; then
    useradd -m -s /bin/rbash -G "$GROUP" "$USER"
    echo "$USER:changeme" | chpasswd
fi

# 2. Create workspace
mkdir -p "$USERHOME/work/public"
chown -R "$USER:$GROUP" "$USERHOME/work"

# 3. Ensure restricted shell
chsh -s /bin/rbash "$USER"

# 4. Create bin folder and symlink safe commands
mkdir -p "$USERHOME/bin"
for cmd in bash git mkdir ls cat nano touch rm cp mv; do
    if command -v $cmd &>/dev/null; then
        ln -s "$(command -v $cmd)" "$USERHOME/bin/$cmd"
    fi
done

# 5. Add safe cd function in .bash_profile
if [ ! -f "$USERHOME/.bash_profile" ]; then
    cat > "$USERHOME/.bash_profile" <<'EOF'
PATH=$HOME/bin
export PATH

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
    chown -R "$USER:$GROUP" "$USERHOME/.bash_profile" "$USERHOME/bin"
fi

echo "✅ Member $USER setup complete."
echo "Workspace: $USERHOME/work/public"
