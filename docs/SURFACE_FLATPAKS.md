# Surface Flatpak Installation

## Automatic Installation (Build-Time)

The Surface variant attempts to install flatpaks automatically during the image build via the `surface-flatpaks.yml` module.

## Post-Deployment Installation (Automatic, One-Time)

If flatpaks aren't installed during the build (or after a system update), a systemd system service automatically runs the installation script on boot.

### How It Works

1. **First boot after rebase/update**: The `install-surface-flatpaks.service` runs automatically during system startup
2. **Script checks deployment**: Compares current deployment checksum with stamp file
3. **Installs if needed**: If no stamp exists or deployment changed, flatpaks are installed
4. **Creates stamp**: Saves deployment checksum to `/var/lib/justin-os/surface-flatpaks-installed`
5. **Subsequent boots**: Script exits immediately if already run for this deployment

This means:

- ✅ Runs once per deployment (after rebase or update)
- ✅ Doesn't run on every boot
- ✅ Automatically handles updates (new deployments get new flatpaks)
- ✅ Safe to leave enabled

## Manual Installation (Fallback)

If you want to manually run the installation:

```bash
# Run the post-installation script
/usr/local/bin/install-surface-flatpaks.sh
```

This script will:

- Ensure Flathub is configured
- Attempt to install all Surface-optimized flatpaks
- Report which apps succeeded and which failed
- Continue even if individual apps fail (useful if some app IDs are invalid)

### What Gets Installed

The script installs the following categories of apps:

- **Browsers**: Touch-friendly browsers (Brave, Chrome)
- **GNOME Core Apps**: Calculator, Calendar, Maps, Weather, etc.
- **Productivity**: Bitwarden, Joplin, Anki, Nextcloud
- **Communication**: Discord, Zoom
- **Media**: Jellyfin, Plex
- **Drawing/Notes**: Xournal++, Krita (stylus support)
- **Office**: LibreOffice
- **Utilities**: Flatseal

### Verifying Flatpak IDs

Some apps listed may not be available on Flathub. To verify an app exists:

```bash
flatpak search <app-name>
# or check the website
curl -I https://flathub.org/apps/details/<app.id>
```

### Customizing the List

To customize which apps are installed:

1. Edit `/usr/local/bin/install-surface-flatpaks.sh`
2. Modify the `FLATPAKS` array
3. Delete the stamp file to force reinstall: `sudo rm /var/lib/justin-os/surface-flatpaks-installed`
4. Run the script again or reboot

## Checking Installation Status

View the stamp file to see what deployment has flatpaks installed:

```bash
cat /var/lib/justin-os/surface-flatpaks-installed
```

Check systemd service status:

```bash
systemctl status install-surface-flatpaks.service
```

View logs:

```bash
journalctl -u install-surface-flatpaks.service
```

## Force Reinstall

To force reinstallation on next boot:

```bash
sudo rm /var/lib/justin-os/surface-flatpaks-installed
```

Or run immediately:

```bash
sudo /usr/local/bin/install-surface-flatpaks.sh
```

## Disabling Automatic Installation

If you don't want the automatic installation:

```bash
sudo systemctl disable install-surface-flatpaks.service
```

## Validation Status

✅ **All 25 Flatpak IDs have been verified** and exist on Flathub as of October 2025.

To re-validate the app IDs at any time:

```bash
/usr/local/bin/validate-flatpak-ids.sh
```

The fallback installation script will skip apps that don't exist and report them at the end.
