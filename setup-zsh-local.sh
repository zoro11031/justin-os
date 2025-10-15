#!/bin/bash
# Setup optimized zsh configuration locally (not on justin-os image)
# This replicates the justin-os zsh setup for use on other systems

set -euo pipefail

echo "=========================================="
echo "Justin-OS Zsh Setup Script"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Don't run this as root. Run as your regular user."
   exit 1
fi

# Install required packages
echo "Installing required packages..."
if command -v dnf >/dev/null 2>&1; then
    echo "Detected Fedora/RHEL - using dnf"
    sudo dnf install -y zsh git curl neovim starship
elif command -v apt >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu - using apt"
    sudo apt update
    sudo apt install -y zsh git curl neovim
    # Install starship manually on Debian/Ubuntu
    if ! command -v starship >/dev/null 2>&1; then
        echo "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh
    fi
elif command -v pacman >/dev/null 2>&1; then
    echo "Detected Arch - using pacman"
    sudo pacman -S --needed --noconfirm zsh git curl neovim starship
else
    echo "Unsupported package manager. Please install manually: zsh, git, curl, neovim, starship"
    exit 1
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed"
fi

# Install custom plugins
echo ""
echo "Installing custom plugins..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
else
    echo "zsh-completions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autopair" ]; then
    git clone --depth=1 https://github.com/hlissner/zsh-autopair.git "$ZSH_CUSTOM/plugins/zsh-autopair"
else
    echo "zsh-autopair already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
else
    echo "fast-syntax-highlighting already installed"
fi

# Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
    echo ""
    echo "Backing up existing .zshrc to .zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

# Copy optimized .zshrc
echo ""
echo "Installing optimized .zshrc..."
cp "files/home/.zshrc" "$HOME/.zshrc"

# Create custom config directory and copy files
echo "Installing custom zsh configs..."
mkdir -p "$ZSH_CUSTOM"
cp files/system/usr/share/oh-my-zsh/custom/alias.zsh "$ZSH_CUSTOM/"
cp files/system/usr/share/oh-my-zsh/custom/benchmark.zsh "$ZSH_CUSTOM/"
cp files/system/usr/share/oh-my-zsh/custom/custom_configs.zsh "$ZSH_CUSTOM/"

# Change default shell to zsh
echo ""
echo "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    echo "Default shell changed to zsh"
    echo "You'll need to log out and back in for this to take effect"
else
    echo "Default shell is already zsh"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "What was installed:"
echo "  ✓ Oh My Zsh"
echo "  ✓ zsh-autosuggestions"
echo "  ✓ zsh-completions"
echo "  ✓ zsh-autopair"
echo "  ✓ fast-syntax-highlighting"
echo "  ✓ Optimized .zshrc configuration"
echo "  ✓ Custom aliases (alias.zsh)"
echo "  ✓ Performance tools (benchmark.zsh)"
echo "  ✓ Optional configs (custom_configs.zsh)"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or run 'exec zsh')"
echo "  2. Install starship if not already available"
echo "  3. Run 'zsh-bench' to test startup performance"
echo ""
echo "Your old .zshrc was backed up to ~/.zshrc.backup"
echo ""
