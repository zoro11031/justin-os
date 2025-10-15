#!/bin/bash
# Install Oh My Zsh and essential plugins for all users

set -e

echo "Setting up Oh My Zsh framework..."

# Install Oh My Zsh to /usr/share for system-wide use
OMZ_DIR="/usr/share/oh-my-zsh"
OMZ_CUSTOM="${OMZ_DIR}/custom"

# Force reinstall if directory exists but is incomplete
if [ -d "$OMZ_DIR" ] && [ ! -d "${OMZ_DIR}/plugins" ]; then
    echo "Incomplete Oh My Zsh installation detected, removing..."
    rm -rf "$OMZ_DIR"
fi

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

# Clean up Oh My Zsh installation - remove unused files
echo "Cleaning up Oh My Zsh installation..."

# Remove unused built-in plugins (we only load a few manually)
# Keep only: git, docker, kubectl, systemd (commonly used)
if [[ -d "${OMZ_DIR}/plugins" ]]; then
  cd "${OMZ_DIR}/plugins" || exit 1
  find . -maxdepth 1 -type d ! -name '.' ! -name 'git' ! -name 'docker' ! -name 'kubectl' ! -name 'systemd' -exec rm -rf {} + 2>/dev/null || true
  cd - > /dev/null || exit 1
else
  echo "Warning: ${OMZ_DIR}/plugins not found, skipping plugin cleanup"
fi

# Remove unused themes (we use starship)
if [[ -d "${OMZ_DIR}/themes" ]]; then
  cd "${OMZ_DIR}/themes" || exit 1
  find . -type f ! -name 'robbyrussell.zsh-theme' -delete 2>/dev/null || true
  cd - > /dev/null || exit 1
else
  echo "Warning: ${OMZ_DIR}/themes not found, skipping theme cleanup"
fi

# Remove documentation and other non-essential files
if [[ -d "${OMZ_DIR}" ]]; then
  cd "${OMZ_DIR}" || exit 1
  rm -rf .github/ .git/ CONTRIBUTING.md README.md CODE_OF_CONDUCT.md
  cd - > /dev/null || exit 1
fi

# Copy custom configs from /usr/share/oh-my-zsh/custom to the installation
# (These are deployed via BlueBuild's files module)
echo "Custom config files will be loaded from ${OMZ_CUSTOM}/"

# Set proper permissions
chmod -R 755 "$OMZ_DIR"

echo "Oh My Zsh setup complete!"
echo "Installed plugins:"
echo "  - zsh-autosuggestions"
echo "  - zsh-completions"
echo "  - zsh-autopair"
echo "  - fast-syntax-highlighting"
echo ""
echo "Cleanup complete - removed unused themes and plugins"

