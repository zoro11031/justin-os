# justin-os &nbsp; [![build](https://github.com/zoro11031/justin-os/actions/workflows/build.yml/badge.svg)](https://github.com/zoro11031/justin-os/actions/workflows/build.yml)

Fedora Atomic images tuned for daily development, built on Universal Blue with a lean host and a polished zsh experience.

---

## Variants

| Image | Desktop | Highlights |
| --- | --- | --- |
| `justin-os` | KDE Plasma (Kinoite) | `/bin/sh` → `dash`, zsh for users, curated CLI tools |
| `justin-os-surface` | GNOME (Silverblue + linux-surface) | Touch/stylus extras, Surface-tailored Flatpaks, Microsoft Core Fonts |

---

## Quick Start

1. Begin from any Fedora Atomic base (Silverblue/Kinoite/uBlue).
2. Rebase, reboot, then move to the signed image:

   ```bash
   rpm-ostree rebase ostree-unverified-registry:ghcr.io/zoro11031/justin-os:latest
   systemctl reboot
   rpm-ostree rebase ostree-image-signed:docker://ghcr.io/zoro11031/justin-os:latest
   systemctl reboot
   ```

   Use `justin-os-surface` in place of `justin-os` for Surface hardware.

3. Confirm the deployment with `rpm-ostree status`.

---

## Key Features

- **Zsh** – Powerlevel10k, Zinit, and fast startup defaults; `/bin/sh` stays lightweight by pointing to `dash`.
- **Flatpak-driven apps** – Desktop software installs after deployment and updates via timers, keeping the image small.
- **Surface-on-linux kernel image** – Optional variant layers linux-surface kernel, libwacom tweaks, and stylus-friendly Flatpaks.

---

## Development Environment

After rebasing, you get a helper bundle in `~/Documents/justin-os-scripts/`.

```bash
cd ~/Documents/justin-os-scripts
bash setup-fedora-distrobox.sh              # full stack
bash setup-fedora-distrobox.sh --minimal    # essentials only
```

The script creates (or replaces) a distrobox using `ghcr.io/ublue-os/fedora-toolbox:latest`, installs base build tools, fzf/zoxide/modern CLI helpers, and—unless `--minimal` is used—Python, Node.js, Go, and Rust. Install GUI editors such as VS Code on the host and attach them to the container as needed; the script focuses solely on CLI tooling. It manages PATH exports and aliases idempotently so reruns are safe.

---

## Flatpaks & Updates

Systemd services handle Flatpaks after each new deployment:

- `flatpak-auto-update.timer` → runs weekly to update both user and system scopes; exits quietly if offline.

If Flatpaks aren't installed when you first boot, you can force install all the default Flatpaks found in the common-flatpaks.yml file using the following command:

```bash
bluebuild-flatpak-manager apply all
```

---

## Surface Extras

The Surface variant layers:

- linux-surface kernel and firmware helpers (`iptsd`, `libwacom-surface`, `thermald`)
- Touch/stylus-friendly Flatpaks (Loupe, Weather, Xournal++, Krita, etc.)

---

## Notes & Support

- Third-party scripts that need bash should use `#!/bin/bash`; system `/bin/sh` runs `dash` for speed and POSIX compliance.
- Re-run the distrobox setup anytime to pull updated tooling without worrying about duplicate PATH lines.
- Questions or issues? Open one on GitHub. Contributions and tweaks welcome.
