#!/bin/bash
# Post-installation script to install Surface flatpaks
# Run this if the flatpak module failed during image build

set -e

echo "Installing Surface-optimized Flatpaks..."

# Ensure Flathub is added
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Array of flatpak IDs to install
FLATPAKS=(
    # Browsers (touch-friendly)
    "com.brave.Browser"
    "com.google.Chrome"
    
    # GNOME Core Apps
    "org.gnome.Calculator"
    "org.gnome.Calendar"
    "org.gnome.Cheese"
    "org.gnome.Contacts"
    "org.gnome.Evince"
    "org.gnome.Loupe"
    "org.gnome.Maps"
    "org.gnome.TextEditor"
    "org.gnome.Weather"
    "org.gnome.clocks"
    "org.gnome.Snapshot"
    
    # Productivity
    "com.bitwarden.desktop"
    "net.cozic.joplin_desktop"
    "net.ankiweb.Anki"
    "com.nextcloud.desktopclient.nextcloud"
    
    # Communication
    "com.discordapp.Discord"
    
    # Media (touch-friendly players)
    "com.github.iwalton3.jellyfin-media-player"
    "com.plexamp.Plexamp"
    "tv.plex.PlexDesktop"
    
    # Drawing/Notes (stylus support)
    "com.github.xournalpp.xournalpp"
    "org.kde.krita"
    
    # Office
    "org.libreoffice.LibreOffice"
    
    # Utilities
    "com.github.tchx84.Flatseal"
)

# Install each flatpak, skipping ones that fail
FAILED=()
SUCCEEDED=()

for app in "${FLATPAKS[@]}"; do
    echo "Installing $app..."
    if flatpak install -y flathub "$app" 2>/dev/null; then
        SUCCEEDED+=("$app")
        echo "✓ $app installed successfully"
    else
        FAILED+=("$app")
        echo "✗ $app failed to install (may not exist on Flathub)"
    fi
done

echo ""
echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo "Successfully installed: ${#SUCCEEDED[@]} apps"
echo "Failed: ${#FAILED[@]} apps"

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "Failed apps:"
    for app in "${FAILED[@]}"; do
        echo "  - $app"
    done
fi

echo ""
echo "Done! You may need to log out and back in for some apps to appear."
