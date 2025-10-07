#!/bin/bash
# Validate Flatpak IDs from surface-flatpaks.yml

echo "Validating Flatpak IDs on Flathub..."
echo ""

FLATPAKS=(
    "com.brave.Browser"
    "com.google.Chrome"
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
    "com.bitwarden.desktop"
    "net.cozic.joplin_desktop"
    "net.ankiweb.Anki"
    "com.nextcloud.desktopclient.nextcloud"
    "com.discordapp.Discord"
    "com.github.iwalton3.jellyfin-media-player"
    "com.plexamp.Plexamp"
    "tv.plex.PlexDesktop"
    "com.github.xournalpp.xournalpp"
    "org.kde.krita"
    "org.libreoffice.LibreOffice"
    "com.github.tchx84.Flatseal"
)

VALID=0
INVALID=0

for app in "${FLATPAKS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" "https://flathub.org/apps/details/${app}")
    
    if [ "$status" = "302" ] || [ "$status" = "200" ]; then
        echo "✓ $app ($status)"
        ((VALID++))
    else
        echo "✗ $app ($status) - NOT FOUND"
        ((INVALID++))
    fi
done

echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo "Valid apps: $VALID"
echo "Invalid apps: $INVALID"
