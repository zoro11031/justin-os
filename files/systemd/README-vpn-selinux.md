# OpenVPN SELinux Context Fix

## Problem
On Fedora Kinoite, OpenVPN certificate files in `~/.cert/nm-openvpn/` can reset to the `container_file_t` SELinux context after reboot, preventing OpenVPN from reading them.

## Solution
A systemd service and timer run a helper script that enforces the correct SELinux context for every user directory under `/var/home`. The script prefers `semanage` for a permanent fix, but transparently falls back to `chcon` so the certificates always work.

### Files
- **fix-vpn-selinux.service** - Systemd service that executes the helper script
- **fix-vpn-selinux.timer** - Timer that triggers the service 10 minutes after boot
- **fix-vpn-selinux.sh** - Script that enumerates `/var/home/*/.cert` directories and fixes their SELinux context

### Automatic Installation
These files are **automatically installed** during the justin-os image build via the `system-services.yml` recipe. Both the service and timer are enabled by default.

### How It Works

#### Service (fix-vpn-selinux.service)
- Runs after `NetworkManager.service`
- Executes `/usr/bin/fix-vpn-selinux.sh`
- Relies on the script to enumerate `/var/home/*/.cert` directories
- Stays in `RemainAfterExit` to avoid re-running unnecessarily

#### Timer (fix-vpn-selinux.timer)
- Triggers 10 minutes after boot as a safety net
- Ensures context is fixed even if the service did not run immediately at boot

#### Script (fix-vpn-selinux.sh)
- Verifies SELinux tools are present and enabled
- Uses `semanage` and `restorecon` when available to install permanent context rules
- Logs each `/var/home/*/.cert` directory it processes so the journal clearly shows coverage
- Falls back to a best-effort `chcon` when `semanage` is missing

### Manual Installation (if not using justin-os image)
```bash
# Copy files to system
sudo cp fix-vpn-selinux.service /etc/systemd/system/
sudo cp fix-vpn-selinux.timer /etc/systemd/system/
sudo cp fix-vpn-selinux.sh /usr/bin/fix-vpn-selinux.sh
sudo chmod 0755 /usr/bin/fix-vpn-selinux.sh

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

### Portability & Customization
The helper script automatically handles every user under `/var/home`. To support custom locations, edit `/usr/bin/fix-vpn-selinux.sh` (or override the service `ExecStart`) and redeploy the unit.

### Verification
```bash
# Check if systemd files were installed
systemctl list-unit-files | grep fix-vpn-selinux

# Check service status
systemctl status fix-vpn-selinux.service

# Check timer status
systemctl status fix-vpn-selinux.timer

# View recent logs (shows each processed /var/home/*/.cert directory)
journalctl -u fix-vpn-selinux.service -n 20

# Verify SELinux context (adjust path for your username)
ls -Z ~/.cert/nm-openvpn/
# Should show: unconfined_u:object_r:home_cert_t:s0
```

### Troubleshooting

#### Check for ordering cycles
```bash
journalctl -b | grep "ordering cycle"
```
If you see ordering cycles, verify the service file doesn't have conflicting `Before=/After=` directives.

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
3. **Redundancy**: Immediate (service) and delayed (timer) execution ensure context is fixed
4. **Idempotent**: Script checks each directory safely and logs what it changes
5. **Permanent where possible**: `semanage` rules persist across reboots; `chcon` fallback covers lean systems
6. **Recursive**: Rules apply recursively so subdirectories (including `nm-openvpn/`) are fixed

### Alternative manual fix
The helper script is also installed at `/usr/bin/fix-vpn-selinux.sh` and can be run manually for troubleshooting or testing purposes.
