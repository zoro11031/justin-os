#!/bin/sh
# Weekly flatpak auto-update script
# Updates both user and system flatpaks
# POSIX-compliant for dash

set -e

echo "=========================================="
echo "Flatpak Auto-Update: $(date)"
echo "=========================================="

# Check if we're online
if ! ping -c 1 flathub.org >/dev/null 2>&1; then
    echo "⚠ Cannot reach Flathub. Skipping update (may be offline)."
    exit 0
fi

# Update user flatpaks
echo ""
echo "Updating user flatpaks..."
if flatpak update -y --user; then
    echo "✓ User flatpaks updated successfully"
else
    echo "✗ Failed to update user flatpaks"
    exit 1
fi

# Update system flatpaks (requires pkexec/sudo)
echo ""
echo "Updating system flatpaks..."
if flatpak update -y --system; then
    echo "✓ System flatpaks updated successfully"
else
    echo "⚠ Failed to update system flatpaks (may require authentication)"
    # Don't exit non-zero for system updates since they may need sudo
fi

echo ""
echo "=========================================="
echo "Flatpak update complete!"
echo "=========================================="
