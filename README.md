# justin-os &nbsp; [![bluebuild build badge](https://github.com/zoro11031/justin-os/actions/workflows/build.yml/badge.svg)](https://github.com/zoro11031/justin-os/actions/workflows/build.yml)

A custom Fedora Atomic image for development and daily use, based on Universal Blue.

## What is this?

This is my personal Fedora Atomic image built with [BlueBuild](https://blue-build.org/). It's Fedora Kinoite/Silverblue with development tools, modern CLI utilities, and essential applications pre-configured.

Two builds are available:

- **justin-os**: Fedora Kinoite with KDE Plasma + dash system shell
- **justin-os-surface**: Fedora Silverblue with GNOME + linux-surface kernel (bash system shell)

## What's Different from Stock?

**Shells & Terminal**  
Interactive shell is automatically changed to zsh with Oh My Zsh pre-configured on first boot. The main build uses dash as the system shell (`/bin/sh`) for faster scripts. Includes modern CLI tools: btop, bat, fzf, neovim, fastfetch, and starship prompt.

All existing users will have their default shell changed to zsh automatically on first boot. New users will get zsh by default.

**Development Tools**  
Go, Python, micro editor, and starship prompt. Docker and libvirt for containers and VMs.

**Repositories**  
RPM Fusion (free and nonfree) pre-configured. Surface variant adds linux-surface repo.

**Flatpaks**  
Extensive collection of applications that install automatically on first boot via systemd service. Weekly auto-updates keep everything current without manual intervention.

**Surface Extras (surface variant only)**  
Linux-surface kernel for better hardware support, touchscreen firmware (iptsd), thermald for thermal management, and Surface SecureBoot certificate.

## Installation

You need an existing Fedora Atomic install (Silverblue, Kinoite, or any uBlue variant).

### Main Build (KDE)

First rebase to unsigned image:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/zoro11031/justin-os:latest
systemctl reboot
```

After reboot, switch to signed:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/zoro11031/justin-os:latest
systemctl reboot
```

### Surface Build (GNOME)

Same process, different image:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/zoro11031/justin-os-surface:latest
systemctl reboot

# After reboot:
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/zoro11031/justin-os-surface:latest
systemctl reboot
```

Verify it worked:

```bash
rpm-ostree status
```

## What's Installed

### Development & Productivity

- **Languages**: Go, Python 3
- **Editors**: neovim, micro
- **Shell**: zsh with Oh My Zsh (zsh-autosuggestions, zsh-completions, fast-syntax-highlighting, zsh-autopair)
- **Prompt**: starship
- **Containers/VMs**: docker, libvirt
- **Version Control**: git

### Shell & CLI Tools

- **Modern replacements**: bat (cat), btop (top), eza (ls)
- **Utilities**: fzf, tree, rsync, stow, fastfetch
- **System**: dash (system shell on main build), lm_sensors, htop
- **Network**: curl, wget
- **Archive**: unzip
- **Scripting**: jq (JSON processor), dialog, yad

### GUI Applications

- **System**: gnome-disk-utility

### Flatpaks (Auto-installed on first boot)

**Note:** Flatpaks install automatically on first boot via systemd service. The installation only runs once per deployment, so it won't slow down subsequent boots. Weekly auto-updates keep apps current.

#### Productivity & Office
- Bitwarden (password manager)
- Joplin (notes)
- Anki (flashcards)
- Nextcloud Desktop
- LibreOffice
- OnlyOffice

#### Communication
- Discord
- Zoom

#### Browsers
- Brave Browser
- Google Chrome
- Mozilla Firefox

#### Media & Entertainment
- Jellyfin Media Player
- Plexamp
- Plex Desktop
- MPV
- VLC
- Haruna (video player)
- Elisa (music player)

#### Gaming
- Steam
- ProtonPlus

#### KDE Applications
- Gwenview (image viewer)
- KCalc (calculator)
- Kdenlive (video editor)
- KMahjongg, KMines (games)
- KMyMoney (finance)
- Kolourpaint (paint)
- KRDC (remote desktop)
- Okular (document viewer)
- Skanpage (scanner)

#### Development & Utilities
- Pods (container management)
- Flatseal (flatpak permissions)
- BoxBuddy (toolbox manager)
- Gear Lever (AppImage manager)
- GNOME Calculator

### Surface Build Additions

The `justin-os-surface` variant includes:

- **Kernel**: kernel-surface, kernel-surface-default-watchdog
- **Touchscreen**: iptsd (touchscreen firmware)
- **Hardware**: libwacom-surface, thermald
- **Security**: surface-secureboot certificate
- **Fonts**: Microsoft Core Fonts (Arial, Times New Roman, etc.)

No system shell change (keeps bash as `/bin/sh` to avoid build issues).

## Build Your Own

Want to customize it? Fork the repo and:

1. **Edit package lists** in `recipes/`:
   - `common-packages.yml` - core system utilities
   - `common-packages-dev.yml` - development tools
   - `common-flatpaks.yml` - flatpak applications
   - `common-systemd.yml` - enabled services
2. **Update image name** in `recipe.yml` (change `name:` field)
3. **Push to GitHub** - Actions will automatically build your image
4. **Rebase to your custom image** using the installation instructions above

### Recipe Files

- **recipe.yml** - Main KDE build configuration
- **recipe-surface.yml** - Surface variant with GNOME and Surface kernel
- **common-*.yml** - Shared modules used by both builds
- **vpn-fix.yml** - SELinux fix for OpenVPN certificates
- **dash-shell.yml** - Dash shell configuration (main build only)

Check out the [BlueBuild docs](https://blue-build.org/learn/getting-started/) for more details on customization.

## Requirements

**Hardware:**
- x86_64 CPU
- 8 GB RAM minimum (16 GB recommended)
- 30 GB free disk space minimum
- SSD recommended for best performance

**Software:**
- Existing Fedora Atomic installation (Silverblue, Kinoite, or any Universal Blue variant)
- Fedora 42 or compatible version

**For Surface variant:**
- Microsoft Surface device (tested on Surface Pro 7)
- Secure Boot support recommended (Surface SecureBoot certificate included)

## Verification

Images are signed with cosign. Verify them:

```bash
cosign verify --key cosign.pub ghcr.io/zoro11031/justin-os:latest
```

The `cosign.pub` file is in this repo.

## Troubleshooting

### Flatpaks won't install on first boot

Check the service status:
```bash
systemctl status install-common-flatpaks.service
```

View the service logs:
```bash
journalctl -u install-common-flatpaks.service
```

Run manually if needed:
```bash
sudo /usr/local/bin/install-common-flatpaks.sh
```

The service uses a stamp file (`/var/lib/justin-os/common-flatpaks-installed`) to track completion. It only runs once per deployment.

### Shell didn't change to zsh

The shell change happens automatically on first boot. Check if the service ran:

```bash
systemctl status change-user-shell-zsh.service
```

View the logs:
```bash
journalctl -u change-user-shell-zsh.service
```

Verify your shell:
```bash
echo $SHELL
```

If it didn't change automatically, you can change it manually:
```bash
chsh -s /usr/bin/zsh
```

Then log out and back in for the change to take effect.

### System shell compatibility (main build only)

The main build uses dash as `/bin/sh` for POSIX compliance and performance. If you have scripts that require bash-specific features:

- Use `#!/bin/bash` shebang in your scripts
- Or run with `bash script.sh` explicitly
- See `docs/SYSTEM_SHELL.md` for details

The Surface build keeps bash as the system shell to avoid compatibility issues.

### RPM Fusion download fails

The build includes retry logic, but mirrors can occasionally be slow or unavailable. If a build fails, retry it - builds are cached and subsequent attempts are faster.

### Surface SecureBoot enrollment

After installing the Surface variant, enroll the Surface SecureBoot certificate:

```bash
sudo mokutil --import /usr/share/surface-secureboot/surface.cer
```

Follow the prompts and reboot to complete enrollment.

See `docs/` folder for more troubleshooting guides.

## Documentation

Additional documentation is available in the `docs/` folder:

- **FLATPAK_MANAGEMENT.md** - How flatpak auto-installation and updates work
- **SYSTEM_SHELL.md** - Dash vs bash system shell differences
- **SURFACE_FLATPAKS.md** - Surface-specific flatpak applications
- **MICROSOFT_FONTS.md** - Microsoft Core Fonts installation (Surface build)

## Features

✅ **Auto-configured zsh** - Existing users automatically switched to zsh on first boot  
✅ **Zero maintenance flatpaks** - Install once on first boot, auto-update weekly  
✅ **Modern CLI tools** - bat, btop, fzf, neovim, starship, and more  
✅ **Development ready** - Go, Python, Docker, and libvirt pre-configured  
✅ **Oh My Zsh included** - With popular plugins pre-installed  
✅ **Signed images** - Cryptographically signed with cosign for security  
✅ **Surface optimized** - Dedicated build with linux-surface kernel  
✅ **RPM Fusion enabled** - Free and nonfree repositories ready to use

## Credits

Built on top of:

- [Universal Blue](https://universal-blue.org/) - base images
- [BlueBuild](https://blue-build.org/) - build tooling
- [Fedora Project](https://fedoraproject.org/) - the distro
- [linux-surface](https://github.com/linux-surface) - Surface kernel

---

**Maintainer**: [@zoro11031](https://github.com/zoro11031)  
**Issues**: [Report bugs here](https://github.com/zoro11031/justin-os/issues)
