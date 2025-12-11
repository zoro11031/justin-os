#!/usr/bin/env bash
set -ouex pipefail

systemctl disable --now systemd-oomd
systemctl mask systemd-oomd
