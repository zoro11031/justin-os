#!/bin/bash
# Set zsh as the default shell in /etc/passwd for new users
# This makes $SHELL return /usr/bin/zsh

set -e

echo "Setting zsh as default shell..."

# Change the default shell in useradd defaults
if [ -f /etc/default/useradd ]; then
    sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
    echo "Updated /etc/default/useradd to use zsh"
fi

# Also set it in /etc/adduser.conf if it exists (Debian-style)
if [ -f /etc/adduser.conf ]; then
    sed -i 's|^DSHELL=.*|DSHELL=/usr/bin/zsh|' /etc/adduser.conf
    echo "Updated /etc/adduser.conf to use zsh"
fi

echo "Default shell set to zsh for new users"
echo "Existing users can run: chsh -s /usr/bin/zsh"
