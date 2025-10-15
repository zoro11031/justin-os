#!/bin/bash
# Post-installation script to install common flatpaks
# Runs once after rebase/update, tracks completion with a stamp file

set -e

STAMP_FILE="/var/lib/justin-os/common-flatpaks-installed"

# Check if already run for this deployment
if [ -f "$STAMP_FILE" ]; then
    CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
    INSTALLED_DEPLOYMENT=$(cat "$STAMP_FILE")
    
    if [ "$CURRENT_DEPLOYMENT" = "$INSTALLED_DEPLOYMENT" ]; then
        echo "Flatpaks already installed for this deployment. Exiting."
        exit 0
    fi
fi

echo "Installing common Flatpaks..."

# Ensure Flathub is added
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Array of flatpak IDs to install
FLATPAKS=(
    # Productivity
    "com.bitwarden.desktop"
    "net.cozic.joplin_desktop"
    "net.ankiweb.Anki"
    "com.nextcloud.desktopclient.nextcloud"
    
    # Browsers
    "com.brave.Browser"
    "com.google.Chrome"
    "org.mozilla.firefox"
    
    # Communication
    "com.discordapp.Discord"
    "us.zoom.Zoom"
    
    # Media
    "com.github.iwalton3.jellyfin-media-player"
    "com.plexamp.Plexamp"
    "tv.plex.PlexDesktop"
    "io.mpv.Mpv"
    "org.videolan.VLC"
    "org.kde.haruna"
    "org.kde.elisa"
    
    # Gaming
    "com.valvesoftware.Steam"
    "com.vysp3r.ProtonPlus"
    
    # Office
    "org.libreoffice.LibreOffice"
    "org.onlyoffice.desktopeditors"
    
    # KDE Apps
    "org.kde.gwenview"
    "org.kde.kcalc"
    "org.kde.kdenlive"
    "org.kde.kmahjongg"
    "org.kde.kmines"
    "org.kde.kmymoney"
    "org.kde.kolourpaint"
    "org.kde.krdc"
    "org.kde.okular"
    "org.kde.skanpage"
    
    # Utilities
    "com.github.marhkb.Pods"
    "com.github.tchx84.Flatseal"
    "io.github.dvlv.boxbuddyrs"
    "it.mijorus.gearlever"
    "org.gnome.Calculator"
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

# Mark this deployment as complete
mkdir -p "$(dirname "$STAMP_FILE")"
CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
echo "$CURRENT_DEPLOYMENT" > "$STAMP_FILE"

echo ""
echo "Done! You may need to log out and back in for some apps to appear."
echo "Stamp file created at: $STAMP_FILE"
