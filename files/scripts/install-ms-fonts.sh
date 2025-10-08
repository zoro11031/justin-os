#!/bin/bash
# Install Microsoft Core Fonts on Fedora Silverblue/Kinoite
set -e

echo "Installing Microsoft Core Fonts dependencies..."
rpm-ostree install --idempotent curl cabextract xorg-x11-font-utils fontconfig

echo "Downloading msttcore-fonts-installer..."
cd /tmp
curl -L -o msttcore-fonts-installer.rpm https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

echo "Installing msttcore-fonts-installer..."
rpm-ostree install --idempotent /tmp/msttcore-fonts-installer.rpm

echo "Cleaning up..."
rm -f /tmp/msttcore-fonts-installer.rpm

echo "Microsoft Core Fonts installed successfully!"
echo "Fonts will be available after next boot."
