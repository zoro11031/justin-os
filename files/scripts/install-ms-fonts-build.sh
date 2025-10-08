#!/usr/bin/env bash
# Install Microsoft Core Fonts during image build
set -euo pipefail

# Exit codes
readonly E_DOWNLOAD=1
readonly E_INSTALL=2
readonly E_CACHE=3
readonly E_SELINUX=4

# Create temporary directory
TEMP_DIR=$(mktemp -d) || exit 1
trap "rm -rf ${TEMP_DIR}" EXIT

cd "${TEMP_DIR}"

echo "Downloading msttcore-fonts-installer..."
# Add retries, timeout, and fail on HTTP errors
if ! curl -L -f --retry 3 --retry-delay 5 --max-time 300 \
  -o msttcore-fonts-installer.rpm \
  https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm; then
  echo "ERROR: Failed to download msttcore-fonts-installer" >&2
  exit ${E_DOWNLOAD}
fi

echo "Installing msttcore-fonts-installer to /usr/share/fonts/..."
# Dependencies are already installed, no need for --nodeps
if ! rpm -ivh msttcore-fonts-installer.rpm; then
  echo "ERROR: Failed to install msttcore-fonts-installer" >&2
  exit ${E_INSTALL}
fi

# The installer places fonts in /usr/share/fonts/msttcore/
# Fix SELinux contexts on font directory
echo "Restoring SELinux contexts..."
if ! restorecon -R /usr/share/fonts/; then
  echo "ERROR: Failed to restore SELinux contexts" >&2
  exit ${E_SELINUX}
fi

# Regenerate font cache
echo "Regenerating font cache..."
if ! fc-cache -f; then
  echo "ERROR: Failed to regenerate font cache" >&2
  exit ${E_CACHE}
fi

echo "Microsoft Core Fonts installed successfully to /usr/share/fonts/"
exit 0
