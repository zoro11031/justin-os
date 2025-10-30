#!/bin/sh
# Post-installation script to install common flatpaks
# Runs once after rebase/update, tracks completion with a stamp file
# POSIX-compliant for dash

set -e

STAMP_FILE="/var/lib/justin-os/common-flatpaks-installed"

# Ensure required tools are available
if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak command not found. Aborting." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq command not found. Aborting." >&2
    exit 1
fi

if ! command -v rpm-ostree >/dev/null 2>&1; then
    echo "rpm-ostree command not found. Aborting." >&2
    exit 1
fi

# Check if already run for this deployment - exit silently if so
if [ -f "$STAMP_FILE" ]; then
    CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
    INSTALLED_DEPLOYMENT=$(cat "$STAMP_FILE")
    
    if [ "$CURRENT_DEPLOYMENT" = "$INSTALLED_DEPLOYMENT" ]; then
        # Exit silently without any output to avoid triggering notifications
        exit 0
    fi
fi

echo "Installing common Flatpaks..."

# Ensure Flathub is added
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# List of flatpak IDs to install (POSIX doesn't support arrays, use space-separated list)
FLATPAKS="com.bitwarden.desktop
net.cozic.joplin_desktop
net.ankiweb.Anki
com.nextcloud.desktopclient.nextcloud
com.brave.Browser
com.google.Chrome
org.mozilla.firefox
com.discordapp.Discord
us.zoom.Zoom
com.github.iwalton3.jellyfin-media-player
com.plexamp.Plexamp
tv.plex.PlexDesktop
io.mpv.Mpv
org.videolan.VLC
org.kde.haruna
org.kde.elisa
com.valvesoftware.Steam
com.vysp3r.ProtonPlus
org.libreoffice.LibreOffice
org.onlyoffice.desktopeditors
org.kde.gwenview
org.kde.kcalc
org.kde.kdenlive
org.kde.kmahjongg
org.kde.kmines
org.kde.kmymoney
org.kde.kolourpaint
org.kde.krdc
org.kde.okular
org.kde.skanpage
com.github.marhkb.Pods
com.github.tchx84.Flatseal
io.github.dvlv.boxbuddyrs
it.mijorus.gearlever
org.gnome.Calculator"

# Install each flatpak, skipping ones that fail
FAILED=""
SUCCEEDED=""
FAILED_COUNT=0
SUCCEEDED_COUNT=0

for app in $FLATPAKS; do
    echo "Installing $app..."
    if flatpak install -y flathub "$app" 2>/dev/null; then
        SUCCEEDED="$SUCCEEDED$app
"
        SUCCEEDED_COUNT=$((SUCCEEDED_COUNT + 1))
        echo "✓ $app installed successfully"
    else
        FAILED="$FAILED$app
"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo "✗ $app failed to install (may not exist on Flathub)"
    fi
done

echo ""
echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo "Successfully installed: $SUCCEEDED_COUNT apps"
echo "Failed: $FAILED_COUNT apps"

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo "Failed apps:"
    echo "$FAILED" | while IFS= read -r app; do
        if [ -n "$app" ]; then
            echo "  - $app"
        fi
    done
fi

# Mark this deployment as complete
STAMP_DIR="${STAMP_FILE%/*}"
mkdir -p "$STAMP_DIR"
CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
echo "$CURRENT_DEPLOYMENT" > "$STAMP_FILE"

echo ""
echo "Done! You may need to log out and back in for some apps to appear."
echo "Stamp file created at: $STAMP_FILE"
