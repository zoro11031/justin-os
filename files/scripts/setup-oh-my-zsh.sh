#!/bin/bash
# Install Oh My Zsh and essential plugins for all users

set -e

echo "Setting up Oh My Zsh framework..."

# Install Oh My Zsh to /usr/share for system-wide use
OMZ_DIR="/usr/share/oh-my-zsh"
OMZ_CUSTOM="${OMZ_DIR}/custom"

if [ ! -d "$OMZ_DIR" ]; then
    echo "Installing Oh My Zsh to ${OMZ_DIR}..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
else
    echo "Oh My Zsh already installed"
fi

# Install essential custom plugins (lean and fast)
echo "Installing essential plugins..."

# zsh-autosuggestions - Fish-like autosuggestions
if [ ! -d "${OMZ_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "${OMZ_CUSTOM}/plugins/zsh-autosuggestions"
fi

# zsh-completions - Additional completion definitions
if [ ! -d "${OMZ_CUSTOM}/plugins/zsh-completions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-completions.git \
        "${OMZ_CUSTOM}/plugins/zsh-completions"
fi

# zsh-autopair - Auto-close brackets, quotes, etc.
if [ ! -d "${OMZ_CUSTOM}/plugins/zsh-autopair" ]; then
    git clone --depth=1 https://github.com/hlissner/zsh-autopair.git \
        "${OMZ_CUSTOM}/plugins/zsh-autopair"
fi

# fast-syntax-highlighting - Fast syntax highlighting
if [ ! -d "${OMZ_CUSTOM}/plugins/fast-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
        "${OMZ_CUSTOM}/plugins/fast-syntax-highlighting"
fi

# Set proper permissions
chmod -R 755 "$OMZ_DIR"

echo "Oh My Zsh setup complete!"
echo "Installed plugins:"
echo "  - zsh-autosuggestions"
echo "  - zsh-completions"
echo "  - zsh-autopair"
echo "  - fast-syntax-highlighting"

