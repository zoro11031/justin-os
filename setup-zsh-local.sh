#!/bin/bash
# Update existing Oh My Zsh to match justin-os optimized configuration
# This cleans up your OMZ installation and applies the optimized config

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/zoro11031/justin-os/main"

echo "=========================================="
echo "Justin-OS Zsh Optimization Script"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Don't run this as root. Run as your regular user."
   exit 1
fi

# Check if Oh My Zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh not found at ~/.oh-my-zsh"
    echo "Please install Oh My Zsh first or use the full setup script"
    exit 1
fi

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
    echo "Backing up existing .zshrc to .zshrc.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Clean up Oh My Zsh installation
echo ""
echo "Cleaning up Oh My Zsh installation..."
echo "  - Removing unused plugins (keeping git, docker, kubectl, systemd)"

cd "$ZSH_DIR/plugins" || exit 1
find . -maxdepth 1 -type d ! -name '.' ! -name 'git' ! -name 'docker' ! -name 'kubectl' ! -name 'systemd' -exec rm -rf {} + 2>/dev/null || true

echo "  - Removing unused themes (keeping robbyrussell)"
cd "$ZSH_DIR/themes" || exit 1
find . -type f ! -name 'robbyrussell.zsh-theme' -delete 2>/dev/null || true
find . -type l -delete 2>/dev/null || true

echo "  - Removing documentation files"
cd "$ZSH_DIR" || exit 1
rm -rf .github/ .git/ CONTRIBUTING.md README.md CODE_OF_CONDUCT.md 2>/dev/null || true

# Calculate space saved
FINAL_SIZE=$(du -sh "$ZSH_DIR" | cut -f1)
echo "  ✓ Cleanup complete! Oh My Zsh is now $FINAL_SIZE"

# Install required custom plugins if missing
echo ""
echo "Checking custom plugins..."

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "  - Installing zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "  ✓ zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    echo "  - Installing zsh-completions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
else
    echo "  ✓ zsh-completions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autopair" ]; then
    echo "  - Installing zsh-autopair..."
    git clone --depth=1 https://github.com/hlissner/zsh-autopair.git "$ZSH_CUSTOM/plugins/zsh-autopair"
else
    echo "  ✓ zsh-autopair already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    echo "  - Installing fast-syntax-highlighting..."
    git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
else
    echo "  ✓ fast-syntax-highlighting already installed"
fi

# Install optimized .zshrc
echo ""
echo "Installing optimized .zshrc from GitHub..."
curl -fsSL "$REPO_URL/files/home/.zshrc" -o "$HOME/.zshrc"

# Install custom config files
echo "Installing custom zsh configs from GitHub..."
mkdir -p "$ZSH_CUSTOM"
curl -fsSL "$REPO_URL/files/system/usr/share/oh-my-zsh/custom/alias.zsh" -o "$ZSH_CUSTOM/alias.zsh"
curl -fsSL "$REPO_URL/files/system/usr/share/oh-my-zsh/custom/benchmark.zsh" -o "$ZSH_CUSTOM/benchmark.zsh"
curl -fsSL "$REPO_URL/files/system/usr/share/oh-my-zsh/custom/custom_configs.zsh" -o "$ZSH_CUSTOM/custom_configs.zsh"

echo ""
echo "=========================================="
echo "Optimization Complete!"
echo "=========================================="
echo ""
echo "What changed:"
echo "  ✓ Cleaned up Oh My Zsh (removed ~290 unused plugins, ~140 themes)"
echo "  ✓ Installed optimized .zshrc"
echo "  ✓ Added custom aliases (alias.zsh)"
echo "  ✓ Added performance tools (benchmark.zsh)"
echo "  ✓ Added optional configs (custom_configs.zsh)"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run 'exec zsh')"
echo "  2. Run 'zsh-bench' to test startup performance"
echo "  3. Expected startup time: ~100-200ms (vs 800ms+ stock OMZ)"
echo ""
echo "Your old .zshrc was backed up with a timestamp"
echo ""

