# justin-os &nbsp; [![bluebuild build badge](https://github.com/zoro11031/justin-os/actions/workflows/build.yml/badge.svg)](https://github.com/zoro11031/justin-os/actions/workflows/build.yml)

A custom Fedora Atomic image for development and daily use, based on Universal Blue.

## What is this?

This is my personal Fedora Atomic image built with [BlueBuild](https://blue-build.org/). It's Fedora Kinoite/Silverblue with development tools, modern CLI utilities, and essential applications pre-configured.

Two builds are available:

- **justin-os**: Fedora Kinoite with KDE Plasma + dash system shell
- **justin-os-surface**: Fedora Silverblue with GNOME + linux-surface kernel (bash system shell)

## What's Different from Stock?

**Shells & Terminal**  
Zsh with Oh My Zsh is set as the default shell system-wide. The main build uses dash as the system shell (`/bin/sh`) for faster scripts. Includes modern CLI tools: btop, bat, fzf, neovim, fastfetch, and starship prompt.

All users will use zsh as their default interactive shell.

**Zsh Performance**: Configured for fast startup (~100-200ms vs typical 800ms+ stock Oh My Zsh) with:
- Direct plugin sourcing instead of loading all of Oh My Zsh
- Lazy loading for heavy commands
- Async autosuggestions
- Fish-like history and completions

**Development Tools**  
Go, Python, micro editor, and starship prompt. Docker and libvirt for containers and VMs.

**Repositories**  
RPM Fusion (free and nonfree) pre-configured. Surface variant adds linux-surface repo.

**Flatpaks**  
Extensive collection of applications available via the default-flatpaks module during image build. Optional installation scripts are provided in `~/Documents/justin-os-scripts/` if manual installation is needed.

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

### Zsh Configuration & Aliases

**Useful Aliases**:
- `vim` → `nvim` - Neovim by default
- `please` - Re-run last command with sudo
- `...`, `....`, `.....` - Go up multiple directories
- `d` - Show last 10 directories
- `mkcd <dir>` - Create directory and cd into it
- `extract <file>` - Extract any archive (tar, zip, 7z, etc.)

**Pipe Aliases** (use anywhere in a command):
- `H` - Pipe to head
- `T` - Pipe to tail  
- `G` - Pipe to grep
- `L` - Pipe to less

**Performance Tools**:
- `zsh-bench` - Test shell startup time
- `zsh-clear-cache` - Clear completion cache

**Prompt**: Starship (with robbyrussell theme as fallback)

### GUI Applications

- **System**: gnome-disk-utility

### Flatpaks

Flatpaks are installed via the default-flatpaks module during the image build. If installation fails or you need to reinstall them, optional scripts are available in `~/Documents/justin-os-scripts/`.

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

### Flatpaks didn't install during build

If flatpaks are missing after installation, you can manually install them using the provided scripts:

```bash
cd ~/Documents/justin-os-scripts/
bash install-common-flatpaks.sh
```

For the Surface variant:
```bash
bash install-surface-flatpaks.sh
```

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

✅ **Zsh by default** - System-wide default shell with optimized Oh My Zsh configuration  
✅ **Extensive flatpaks** - Productivity, development, and entertainment apps included  
✅ **Modern CLI tools** - bat, btop, fzf, neovim, starship, ghostty  
✅ **Development ready** - Go, Python, Docker, libvirt  
✅ **Signed images** - Cryptographically signed with cosign  
✅ **Surface optimized** - Dedicated build with linux-surface kernel  
✅ **RPM Fusion enabled** - Free and nonfree repos ready to use

## Credits

Built on top of:

- [Universal Blue](https://universal-blue.org/) - base images
- [BlueBuild](https://blue-build.org/) - build tooling
- [Fedora Project](https://fedoraproject.org/) - the distro
- [linux-surface](https://github.com/linux-surface) - Surface kernel

---

**Maintainer**: [@zoro11031](https://github.com/zoro11031)  
**Issues**: [Report bugs here](https://github.com/zoro11031/justin-os/issues)
