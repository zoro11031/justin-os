#!/bin/bash
# Update existing Zsh configuration to match justin-os optimized zinit setup
# This script updates your local zsh config to use zinit and powerlevel10k

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/zoro11031/justin-os/main"

echo "=========================================="
echo "Justin-OS Zsh Setup Script"
echo "Migrating to Zinit + Powerlevel10k"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Don't run this as root. Run as your regular user."
   exit 1
fi

# Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
    echo "Backing up existing .zshrc to .zshrc.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Backup existing .p10k.zsh if it exists
if [ -f "$HOME/.p10k.zsh" ]; then
    echo "Backing up existing .p10k.zsh to .p10k.zsh.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Clean up old oh-my-zsh installation if it exists
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "Found old Oh My Zsh installation at ~/.oh-my-zsh"
    read -p "Do you want to remove it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing ~/.oh-my-zsh..."
        rm -rf "$HOME/.oh-my-zsh"
        echo "✓ Removed"
    else
        echo "Keeping old installation (may cause conflicts)"
    fi
fi

# Install optimized .zshrc
echo ""
echo "Installing optimized .zshrc with zinit from GitHub..."
curl -fsSL "$REPO_URL/files/home/.zshrc" -o "$HOME/.zshrc"

# Install default p10k config
echo "Installing default Powerlevel10k configuration..."
curl -fsSL "$REPO_URL/files/home/.p10k.zsh" -o "$HOME/.p10k.zsh"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "What changed:"
echo "  ✓ Clean Zinit configuration installed"
echo "  ✓ Powerlevel10k theme configured"
echo "  ✓ Zinit will auto-install on first shell launch"
echo "  ✓ All plugins will be downloaded automatically"
echo "  ✓ Installed default p10k configuration"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run 'exec zsh')"
echo "  2. On first launch, zinit will auto-install"
echo "  3. Run 'p10k configure' to customize your prompt (optional)"
echo "  4. Run 'zsh-bench' to test startup performance"
echo ""
echo "Your old .zshrc was backed up with a timestamp"
echo ""
echo "Features included:"
echo "  • Powerlevel10k prompt theme"
echo "  • Fast syntax highlighting"
echo "  • Auto-suggestions"
echo "  • Auto-pair brackets/quotes"
echo "  • fzf-tab completions"
echo "  • Git, AWS, kubectl integrations"
echo "  • Clean, minimal configuration"
echo ""
