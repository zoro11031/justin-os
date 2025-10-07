# Surface Flatpak Installation

## Automatic Installation (Build-Time)

The Surface variant attempts to install flatpaks automatically during the image build via the `surface-flatpaks.yml` module.

## Manual Installation (Post-Build Fallback)

If the flatpak module fails during build or if you want to reinstall the apps later, a fallback script is included in the image.

### Running the Fallback Script

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
3. Run the script again

## Validation Status

✅ **All 25 Flatpak IDs have been verified** and exist on Flathub as of October 2025.

To re-validate the app IDs at any time:

```bash
/usr/local/bin/validate-flatpak-ids.sh
```

The fallback installation script will skip apps that don't exist and report them at the end.
