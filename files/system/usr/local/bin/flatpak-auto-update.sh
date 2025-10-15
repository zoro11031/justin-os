#!/bin/bash
# Weekly flatpak auto-update script
# Updates system flatpaks

set -e

echo "=========================================="
echo "Flatpak Auto-Update: $(date)"
echo "=========================================="

# Check if we're online
if ! ping -c 1 flathub.org &> /dev/null; then
    echo "⚠ Cannot reach Flathub. Skipping update (may be offline)."
    exit 0
fi

# Update system flatpaks
echo "Updating system flatpaks..."
if flatpak update -y; then
    echo "✓ System flatpaks updated successfully"
else
    echo "✗ Failed to update system flatpaks"
    exit 1
fi

echo "=========================================="
echo "Flatpak update complete!"
echo "=========================================="
