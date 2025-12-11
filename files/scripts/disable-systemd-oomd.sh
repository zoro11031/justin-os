#!/usr/bin/env bash
# Disable and mask systemd-oomd.service to prevent conflicts with nohang
set -euo pipefail

echo "Disabling and masking systemd-oomd..."
systemctl disable systemd-oomd.service
systemctl mask systemd-oomd.service
