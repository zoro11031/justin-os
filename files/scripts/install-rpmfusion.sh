#!/usr/bin/env bash
# Add RPM Fusion repositories with retry logic
set -euo pipefail

readonly E_DOWNLOAD=1

TEMP_DIR=$(mktemp -d) || exit 1
trap "rm -rf ${TEMP_DIR}" EXIT

cd "${TEMP_DIR}"

echo "Downloading RPM Fusion Free repository..."
if ! curl -L -f --retry 3 --retry-delay 5 --max-time 180 \
  -o rpmfusion-free-release-42.noarch.rpm \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm; then
  echo "ERROR: Failed to download RPM Fusion Free repository" >&2
  exit ${E_DOWNLOAD}
fi

echo "Downloading RPM Fusion Nonfree repository..."
if ! curl -L -f --retry 3 --retry-delay 5 --max-time 180 \
  -o rpmfusion-nonfree-release-42.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm; then
  echo "ERROR: Failed to download RPM Fusion Nonfree repository" >&2
  exit ${E_DOWNLOAD}
fi

echo "Installing RPM Fusion repositories..."
rpm -ivh rpmfusion-free-release-42.noarch.rpm rpmfusion-nonfree-release-42.noarch.rpm

echo "RPM Fusion repositories installed successfully!"
exit 0
