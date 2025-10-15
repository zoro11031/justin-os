# Flatpak Management

This image includes intelligent flatpak management to avoid boot-time overhead and keep your apps up-to-date.

## Two-Part Strategy

### 1. One-Time Installation After Deployment

Common flatpaks are **not** installed during every boot. Instead:

- A systemd system service (`install-common-flatpaks.service`) runs once after you rebase or update to a new deployment
- The script tracks which deployment you're on using the rpm-ostree checksum
- If the deployment hasn't changed, it skips installation entirely
- This keeps boot times fast and avoids unnecessary network traffic

**Installed Apps:** ~40+ applications including:

- **Productivity**: Bitwarden, Joplin, Anki, Nextcloud
- **Browsers**: Brave, Chrome, Firefox
- **Communication**: Discord, Zoom
- **Media**: Jellyfin, Plex, MPV, VLC, Haruna, Elisa
- **Gaming**: Steam, ProtonPlus
- **Office**: LibreOffice, OnlyOffice
- **KDE Apps**: Gwenview, Kdenlive, Okular, Kcalc, and more
- **Utilities**: Pods, Flatseal, BoxBuddy, Gear Lever

### 2. Weekly Auto-Updates

A systemd timer (`flatpak-auto-update.timer`) runs weekly to:

- Update all system flatpaks
- Run with a randomized delay to spread network load
- Skip gracefully if offline

This keeps your apps current without manual intervention.

## How It Works

### Initial Installation

When you first boot after rebasing to justin-os or after an OS update:

1. The system boots up
2. The `install-common-flatpaks.service` activates automatically during boot
3. It checks: "Have I already run for this deployment?"
4. If not, it installs all flatpaks (system scope) and creates a stamp file at `/var/lib/justin-os/common-flatpaks-installed`
5. The stamp file contains the rpm-ostree checksum of your current deployment

On subsequent boots:

- The service runs again but sees the stamp file matches your current deployment
- It exits immediately, adding no boot time overhead

### Weekly Updates

The timer runs once per week (with up to 1 hour randomization):

- Updates system flatpaks
- Logs output to the journal
- Handles offline gracefully (doesn't fail if network is down)

## Manual Control

### Check Service Status

```bash
systemctl status install-common-flatpaks.service
```

### View Installation Logs

```bash
journalctl -u install-common-flatpaks.service
```

### Force Reinstall

If you want to force a reinstall (e.g., you manually removed some apps):

```bash
sudo rm /var/lib/justin-os/common-flatpaks-installed
sudo systemctl restart install-common-flatpaks.service
```

### Check Timer Status

```bash
systemctl status flatpak-auto-update.timer
systemctl list-timers  # Shows next run time
```

### View Update Logs

```bash
journalctl -u flatpak-auto-update.service
```

### Manually Run Update

```bash
/usr/local/bin/flatpak-auto-update.sh
```

### Disable Auto-Updates

If you prefer to update manually:

```bash
sudo systemctl disable flatpak-auto-update.timer
sudo systemctl stop flatpak-auto-update.timer
```

## Troubleshooting

### Apps Not Installing

If apps fail to install after rebase:

### Apps Not Installing

If apps fail to install after rebase:

1. Check the service status: `systemctl status install-common-flatpaks.service`
2. View detailed logs: `journalctl -u install-common-flatpaks.service`
3. Try running manually: `sudo /usr/local/bin/install-common-flatpaks.sh`
4. Some apps may not be available in your region or may have been removed from Flathub

### Updates Failing

If weekly updates are failing:

1. Check the service logs: `journalctl -u flatpak-auto-update.service`
2. Verify network connectivity: `ping flathub.org`
3. Try updating manually: `flatpak update -y`

### Service Not Running

The service may not run if:

- Systemd system services aren't starting (check `systemctl status`)
- The stamp file directory has permission issues
- Network is unavailable during boot

Fix permission issues:

```bash
sudo mkdir -p /var/lib/justin-os
sudo chmod 755 /var/lib/justin-os
```

## Technical Details

### Stamp File Location

- **Common flatpaks**: `/var/lib/justin-os/common-flatpaks-installed`
- **Surface flatpaks**: `/var/lib/justin-os/surface-flatpaks-installed` (Surface variant)

### Deployment Tracking

The stamp file contains the rpm-ostree deployment checksum. When you update the OS:

- A new deployment is created with a different checksum
- The service detects this mismatch
- Apps are reinstalled (in case new apps were added to the image recipe)
- The stamp file is updated with the new checksum

### Why Not Build-Time?

Installing flatpaks at build time has drawbacks:

- Increases container image size significantly
- Makes builds slower
- Requires rebuilding the entire image to add/remove apps
- Creates a cache in the image that goes stale

The post-deployment approach:

- Keeps the image small and fast to build
- Downloads the latest versions of apps
- Only runs once per deployment (not every boot)
- Allows easy customization (just edit the script)

### Scope: User vs System

**All flatpaks** in both variants (main and Surface) are installed to **system scope** because:

- Available to all users on the system
- Consistent with the recipe configuration
- Single installation shared across users
- Better for multi-user systems
- More efficient use of disk space

The system scope flatpak (`org.gnome.Loupe`) is installed at build time since it's a core image viewer.
