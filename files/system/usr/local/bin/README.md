# Scripts in /usr/local/bin

These scripts are automatically copied to the image during build time.

## Flatpak Management Scripts

### install-common-flatpaks.sh
cd - Installs ~40 flatpak applications at system scope
cd - Runs once per deployment via systemd service
cd - Tracks completion with stamp file at `/var/lib/justin-os/common-flatpaks-installed`
cd - Used in main (KDE) variant

### install-surface-flatpaks.sh
cd - Installs ~25 Surface-optimized flatpak applications at system scope
cd - Runs once per deployment via systemd service
cd - Tracks completion with stamp file at `/var/lib/justin-os/surface-flatpaks-installed`
cd - Used in Surface (GNOME) variant

### flatpak-auto-update.sh
cd - Weekly automatic update of system flatpaks
cd - Triggered by systemd timer
cd - Handles offline gracefully
cd - Used in both variants

All scripts require `jq` package for JSON parsing (rpm-ostree status).
