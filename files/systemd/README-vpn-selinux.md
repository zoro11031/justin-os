# OpenVPN SELinux Context Fix

## Problem
On Fedora Kinoite, OpenVPN certificate files in `~/.cert/nm-openvpn/` get reset to `container_file_t` SELinux context after reboot, preventing OpenVPN from reading them.

## Solution
This solution uses a systemd service and timer to automatically fix the SELinux context on boot and periodically.

### Files
- **fix-vpn-selinux.service** - Systemd service that runs chcon to fix SELinux context
- **fix-vpn-selinux.timer** - Timer that triggers the service 10 minutes after boot
- **fix-vpn-selinux.sh** - Script with more advanced semanage-based permanent fix (optional)

### How It Works

#### Service (fix-vpn-selinux.service)
- Runs after NetworkManager.service starts
- Executes: `/usr/bin/chcon -R -t home_cert_t /var/home/justin/.cert`
- Sets SELinux context to `home_cert_t` (correct context for certificate files)
- No circular dependencies (fixed by removing `Before=NetworkManager.service`)

#### Timer (fix-vpn-selinux.timer)
- Triggers 10 minutes after boot as a safety net
- Ensures context is fixed even if service doesn't run immediately at boot

### Installation
```bash
# Copy files to system
sudo cp fix-vpn-selinux.service /etc/systemd/system/
sudo cp fix-vpn-selinux.timer /etc/systemd/system/

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

### Verification
```bash
# Check if files were installed
systemctl list-unit-files | grep fix-vpn-selinux

# Check service status
systemctl status fix-vpn-selinux.service

# Check timer status
systemctl status fix-vpn-selinux.timer

# View recent logs
journalctl -u fix-vpn-selinux.service -n 20

# Verify SELinux context
ls -Z ~/.cert/nm-openvpn/
# Should show: unconfined_u:object_r:home_cert_t:s0
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
