# Microsoft Fonts Installation on justin-os-surface

## Overview

The Surface variant includes Microsoft Core Fonts for better document compatibility and rendering.

## What Gets Installed

The following Microsoft Core Fonts are included:

- Arial
- Times New Roman
- Courier New
- Comic Sans MS
- Impact
- Verdana
- Georgia
- Trebuchet MS
- Webdings
- Wingdings

## How It Works

### Build-Time Installation (Automatic)

During image build, the system:

1. **Installs dependencies** via rpm-ostree:

   - `curl` - for downloading files
   - `cabextract` - for extracting CAB files
   - `xorg-x11-font-utils` - font utilities
   - `fontconfig` - font configuration system

2. **Runs the build script** (`install-ms-fonts-build.sh`):
   - Downloads `msttcore-fonts-installer-2.6-1.noarch.rpm` from SourceForge
   - Installs it via rpm-ostree
   - The installer automatically downloads and installs the Microsoft fonts
   - Cleans up temporary files

### Post-Installation (Manual Fallback)

If the build-time installation fails, you can install manually after boot:

```bash
/usr/local/bin/install-ms-fonts.sh
```

This script requires a reboot to take effect since it uses rpm-ostree.

## Verification

After installation (and reboot if manual), verify fonts are available:

```bash
fc-list | grep -i "arial\|times\|courier"
```

You should see entries for Arial, Times New Roman, Courier New, etc.

## Technical Details

### Why msttcore-fonts-installer?

The `msttcore-fonts-installer` package:

- Downloads fonts directly from Microsoft's servers
- Handles license acceptance automatically
- Properly installs fonts system-wide
- Works correctly with immutable systems like Silverblue

### File Locations

- **Build script**: `/files/scripts/install-ms-fonts-build.sh` (runs during build)
- **Manual script**: `/files/scripts/install-ms-fonts.sh` (available at `/usr/local/bin/install-ms-fonts.sh`)
- **Installed fonts**: `/usr/share/fonts/msttcore/` (after installation)
- **Font cache**: Updated automatically by fontconfig

## Troubleshooting

### Build fails to download from SourceForge

If the build environment can't reach SourceForge:

- Check network connectivity from CI runner
- Consider vendoring the RPM into the repository
- Use the manual installation script after boot

### Fonts don't appear after installation

1. Ensure you rebooted after manual installation (rpm-ostree requires this)
2. Regenerate font cache: `fc-cache -fv`
3. Check font installation: `rpm -qa | grep msttcore`

### License Concerns

Microsoft Core Fonts are freely distributable but have specific license terms. The msttcore-fonts-installer handles license acceptance. For commercial use, review Microsoft's font license terms.

## Alternative: Manual RPM Installation

If you prefer not to use the automated scripts:

```bash
# Download the installer
curl -L -o /tmp/msttcore-fonts-installer.rpm \
  https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

# Install it
sudo rpm-ostree install /tmp/msttcore-fonts-installer.rpm

# Reboot
systemctl reboot
```

## References

- [msttcore-fonts project on SourceForge](https://sourceforge.net/projects/mscorefonts2/)
- [Microsoft's Core Fonts for the Web](https://en.wikipedia.org/wiki/Core_fonts_for_the_Web)
