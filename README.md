# justin-os &nbsp; [![bluebuild build badge](https://github.com/zoro11031/justin-os/actions/workflows/build.yml/badge.svg)](https://github.com/zoro11031/justin-os/actions/workflows/build.yml)

A custom Fedora Atomic image for development and virtualization, based on Universal Blue.

## What is this?

This is my personal Fedora Atomic image built with [BlueBuild](https://blue-build.org/). It's basically stock Fedora Kinoite/Silverblue with dev tools, virtualization, and utilities already layered in so you don't have to install them after rebasing.

Two builds are available:

- **main**: Fedora Kinoite with KDE Plasma
- **surface**: Fedora Silverblue with GNOME (better for touchscreens) + linux-surface kernel

## What's Different from Stock?

**Shells**  
Your interactive shell is zsh. The system shell (`/bin/sh`) uses dash instead of bash for faster boot and script execution.

**Development**  
Currently working with Go and Python, so those toolchains are included. Other languages and tools will be added as needed.

**Virtualization**  
Full libvirt/KVM stack with virt-manager, QEMU, and everything for running VMs out of the box.

**CLI Tools**  
Modern replacements: btop instead of top, bat instead of cat, plus fzf, neovim, fastfetch.

**Repositories**  
RPM Fusion (free and nonfree) comes pre-configured with retry logic for reliable builds.

**Fonts**  
Microsoft Core Fonts (Arial, Times New Roman, etc.) included in both builds for document compatibility.

**Surface Extras**  
The Surface build adds linux-surface kernel, touchscreen firmware (iptsd), and touch-friendly flatpaks.

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

### Development

- git, go, python3, pip
- gopls (Go language server)
- ShellCheck, shfmt (shell script tools)
- docker, docker-compose
- Node.js tooling (for language servers)

_Languages and tools are added as needed - currently focused on Go and Python development._

### Virtualization

- libvirt, qemu-kvm, virt-manager
- virt-install, virt-viewer, virt-top
- libvirt networking and KVM daemon
- remmina (remote desktop)
- spice-gtk, swtpm, edk2-ovmf
- guestfs-tools, libguestfs

### Shell & Terminal

- zsh (your shell), dash (system shell), bash (still available)
- bat, btop, htop, fastfetch
- fzf, tree, stow, dialog, yad
- neovim, micro
- lm_sensors

### System Stuff

- curl, wget, rsync, unzip
- gnome-disk-utility
- Microsoft Core Fonts (both builds)

### Flatpaks (Pre-configured)

Apps install automatically after first boot (not during every boot - keeps things fast):

- **Productivity**: Bitwarden, Joplin, Anki, Nextcloud
- **Communication**: Discord, Zoom
- **Browsers**: Brave, Chrome, Firefox
- **Office**: LibreOffice, OnlyOffice
- **Media**: Jellyfin, Plex, MPV, VLC
- **Gaming**: Steam, ProtonPlus
- **KDE Apps**: Gwenview, Kdenlive, Okular, and more
- **Utilities**: Flatseal, Pods, BoxBuddy, Gear Lever

Apps update automatically every week via systemd timer. See `docs/FLATPAK_MANAGEMENT.md` for details.

## Build Your Own

Want to customize it? Fork the repo and:

1. Edit package lists in `recipes/`:
   - `common-packages.yml` - core utilities
   - `common-packages-dev.yml` - development tools
   - `common-flatpaks.yml` - flatpak apps
2. Update `recipe.yml` with your image name
3. Push to GitHub (Actions will build it)
4. Rebase to your custom image

Check out the [BlueBuild docs](https://blue-build.org/learn/getting-started/) for more info.

## Requirements

**Minimum:**

- x86_64 CPU with virtualization (Intel VT-x / AMD-V)
- 8 GB RAM (16 GB if running VMs)
- 30 GB free disk space
- Fedora Atomic 39+

**Recommended:**

- Modern multi-core CPU
- 16 GB+ RAM
- SSD with 50+ GB space

## Verification

Images are signed with cosign. Verify them:

```bash
cosign verify --key cosign.pub ghcr.io/zoro11031/justin-os:latest
```

The `cosign.pub` file is in this repo.

## Troubleshooting

**RPM Fusion download fails?**  
Retry the build. The image uses retry logic but sometimes mirrors are flaky.

**Flatpaks won't install?**  
Check the service status: `systemctl status install-common-flatpaks.service`  
Or run manually: `sudo /usr/local/bin/install-common-flatpaks.sh`

See `docs/FLATPAK_MANAGEMENT.md` for troubleshooting.

**Script breaks with /bin/sh?**  
The system shell is dash (POSIX-compliant). Use `#!/bin/bash` for bash-specific scripts or run with `bash script.sh`.

See `docs/SYSTEM_SHELL.md` for details.

## More Info

Docs are in the `docs/` folder:

- `FLATPAK_MANAGEMENT.md` - one-time installs + weekly auto-updates
- `SYSTEM_SHELL.md` - dash vs bash
- `SURFACE_FLATPAKS.md` - Surface-specific flatpaks
- `MICROSOFT_FONTS.md` - font installation

## Credits

Built on top of:

- [Universal Blue](https://universal-blue.org/) - base images
- [BlueBuild](https://blue-build.org/) - build tooling
- [Fedora Project](https://fedoraproject.org/) - the distro
- [linux-surface](https://github.com/linux-surface) - Surface kernel

---

**Maintainer**: [@zoro11031](https://github.com/zoro11031)  
**Issues**: [Report bugs here](https://github.com/zoro11031/justin-os/issues)
