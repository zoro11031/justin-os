# OpenVPN SELinux Context Fix

## Problem
On Fedora Kinoite, OpenVPN certificate files in `~/.cert/nm-openvpn/` get reset to `container_file_t` SELinux context after reboot, preventing OpenVPN from reading them.

## Solution
This solution uses a systemd service and timer to automatically fix the SELinux context on boot and periodically. The service targets the parent `.cert` directory recursively, which includes the `nm-openvpn` subdirectory and any other certificate subdirectories.

### Files
- **fix-vpn-selinux.env** - Environment file for configurable paths (portable)
- **fix-vpn-selinux.service** - Systemd service that runs chcon to fix SELinux context
- **fix-vpn-selinux.timer** - Timer that triggers the service 10 minutes after boot
- **fix-vpn-selinux.sh** - Optional script with semanage-based approach (can be run manually)

### Automatic Installation
These files are **automatically installed** during the justin-os image build via the `system-services.yml` recipe. Both the service and timer are enabled by default. You only need the manual installation steps below if you're not using the justin-os image or want to update the files on an existing system.

### How It Works

#### Environment File (fix-vpn-selinux.env)
- Located at `/etc/fix-vpn-selinux.env`
- Defines `VPN_CERT_PATH` (default: `/var/home/justin/.cert`)
- Defines `VPN_CERT_CONTEXT` (default: `home_cert_t`)
- **Customizable**: Edit this file to change paths without modifying the service

#### Service (fix-vpn-selinux.service)
- Runs after NetworkManager.service starts
- Reads configuration from `/etc/fix-vpn-selinux.env`
- Executes: `/usr/bin/chcon -R -t ${VPN_CERT_CONTEXT} ${VPN_CERT_PATH}`
- Default target: `/var/home/justin/.cert` (recursively includes `nm-openvpn/` subdirectory)
- Sets SELinux context to `home_cert_t` (correct context for certificate files)
- No circular dependencies (fixed by removing `Before=NetworkManager.service`)

#### Timer (fix-vpn-selinux.timer)
- Triggers 10 minutes after boot as a safety net
- Ensures context is fixed even if service doesn't run immediately at boot

### Manual Installation (if not using justin-os image)
```bash
# Copy files to system
sudo cp fix-vpn-selinux.env /etc/fix-vpn-selinux.env
sudo cp fix-vpn-selinux.service /etc/systemd/system/
sudo cp fix-vpn-selinux.timer /etc/systemd/system/

# IMPORTANT: Edit environment file for your username if not 'justin'
sudo nano /etc/fix-vpn-selinux.env
# Change: VPN_CERT_PATH=/var/home/YOUR_USERNAME/.cert

# Reload systemd
sudo systemctl daemon-reload

# Enable both service and timer
sudo systemctl enable fix-vpn-selinux.service
sudo systemctl enable fix-vpn-selinux.timer

# Start timer (service will run automatically on next boot or via timer)
sudo systemctl start fix-vpn-selinux.timer

# Manually run once to fix immediately (optional)
sudo systemctl start fix-vpn-selinux.service
```

## Portability & Customization

### For Different Users
The default configuration is set for user `justin` in the justin-os image. To customize for your environment:

**Option 1: Edit the environment file** (Recommended)
```bash
sudo nano /etc/fix-vpn-selinux.env
```

Change the path to match your username:
```bash
VPN_CERT_PATH=/var/home/YOUR_USERNAME/.cert
```

**Option 2: For multiple users**
Use the included `fix-vpn-selinux.sh` script instead, which automatically processes all users:
```bash
# Edit the service file to call the script
sudo nano /etc/systemd/system/fix-vpn-selinux.service

# Change ExecStart to:
# ExecStart=/usr/bin/fix-vpn-selinux.sh
```

### Path Explanation
- **Target**: `/var/home/justin/.cert` (parent directory)
- **Recursively includes**: All subdirectories including `nm-openvpn/`
- **Why parent directory**: Using `-R` flag fixes the entire certificate tree at once
- **Fedora Kinoite**: Uses `/var/home` instead of `/home` for user directories

### Forking justin-os
If you fork this repository to create your own custom image:

1. Edit `files/systemd/fix-vpn-selinux.env`
2. Change `VPN_CERT_PATH=/var/home/YOUR_USERNAME/.cert`
3. Rebuild the image - your customization will be included automatically

### Verification
```bash
# Check environment configuration
cat /etc/fix-vpn-selinux.env

# Check if systemd files were installed
systemctl list-unit-files | grep fix-vpn-selinux

# Check service status
systemctl status fix-vpn-selinux.service

# Check timer status
systemctl status fix-vpn-selinux.timer

# View recent logs
journalctl -u fix-vpn-selinux.service -n 20

# Verify SELinux context (adjust path for your username)
ls -Z ~/.cert/nm-openvpn/
# Should show: unconfined_u:object_r:home_cert_t:s0
# The important part is: home_cert_t (not container_file_t)
```

### Troubleshooting

#### Check for ordering cycles
```bash
journalctl -b | grep "ordering cycle"
```
If you see ordering cycles, verify the service file doesn't have conflicting Before/After directives.

#### Manual fix
If you need to fix the context immediately:
```bash
chcon -R -t home_cert_t ~/.cert
```

#### Verify NetworkManager dependency
```bash
systemctl list-dependencies fix-vpn-selinux.service
```

## Technical Details

### Why This Fix Works
1. **No circular dependencies**: Service only uses `After=NetworkManager.service` without `Before=` clauses
2. **Proper ordering**: Waits for NetworkManager to start before fixing certificates
3. **Redundancy**: Both immediate (service) and delayed (timer) execution ensure context is fixed
4. **Idempotent**: chcon can be run multiple times safely
5. **Portable**: Environment file makes customization easy without modifying service files
6. **Recursive**: `-R` flag ensures all subdirectories (including `nm-openvpn/`) are fixed

### Original Problem
The original service had:
```
After=local-fs.target
Before=NetworkManager.service
WantedBy=multi-user.target
```

This created an ordering cycle:
- multi-user.target → graphical.target → NetworkManager.service → fix-vpn-selinux.service → multi-user.target

### Fixed Configuration
```
After=NetworkManager.service
WantedBy=multi-user.target
```

This breaks the cycle by only having forward dependencies.

### Alternative: Using the Script (fix-vpn-selinux.sh)
The `fix-vpn-selinux.sh` script is included and uses `semanage` to create permanent SELinux rules. However, on Fedora Kinoite, the context still gets reset after reboot due to how the immutable filesystem handles `/var/home`.

The script is useful for:
- Manual troubleshooting: Run `/usr/bin/fix-vpn-selinux.sh` to try semanage approach
- Systems where semanage works properly
- Understanding the "proper" SELinux fix approach

The service uses the simpler `chcon` approach with a timer for periodic re-application, which is more reliable on Fedora Kinoite.
