#!/bin/bash
# Configure system-wide shells to default to zsh for interactive sessions.

set -euo pipefail

# Ensure /usr/bin/zsh exists before configuring.
if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh is not installed; skipping default shell configuration" >&2
    exit 0
fi

echo "Configuring /etc/bashrc to auto-launch zsh..."

if ! grep -q "exec /usr/bin/zsh" /etc/bashrc 2>/dev/null; then
    cat >> /etc/bashrc <<'CONFIG_EOF'

# Auto-launch zsh for interactive shells
[ -n "$PS1" ] && exec /usr/bin/zsh
CONFIG_EOF
    echo "Added zsh auto-launch to /etc/bashrc"
else
    echo "zsh auto-launch already configured in /etc/bashrc"
fi

# Update /etc/shells if zsh is missing so chsh can be used later.
if ! grep -qx "/usr/bin/zsh" /etc/shells; then
    echo "/usr/bin/zsh" >> /etc/shells
    echo "Registered /usr/bin/zsh in /etc/shells"
fi

echo "Bash will now launch zsh for interactive sessions"
