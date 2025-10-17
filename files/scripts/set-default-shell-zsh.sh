#!/bin/bash
# Auto-launch zsh from bashrc for interactive shells
# This makes bash automatically exec into zsh without changing the default shell

set -euo pipefail

echo "Configuring bashrc to auto-launch zsh..."

# Add zsh exec to /etc/bashrc for all users
if ! grep -q "exec /usr/bin/zsh" /etc/bashrc 2>/dev/null; then
    cat >> /etc/bashrc << 'EOF'

# Auto-launch zsh for interactive shells
[ ! -z "$PS1" ] && exec /usr/bin/zsh
EOF
    echo "Added zsh auto-launch to /etc/bashrc"
else
    echo "zsh auto-launch already configured in /etc/bashrc"
fi

echo "Bash will now automatically launch zsh for interactive sessions"
