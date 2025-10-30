#!/usr/bin/env bash
set -euo pipefail

# Convenience script to create a Fedora 42 distrobox for development
# Usage: bash scripts/setup-fedora-distrobox.sh [--with-code-server]

CONTAINER_NAME=dev-fedora-42
IMAGE=registry.fedoraproject.org/fedora:42
INSTALL_CODE_SERVER=0

for arg in "$@"; do
  case "$arg" in
    --with-code-server) INSTALL_CODE_SERVER=1 ;;
    --name=*) CONTAINER_NAME="${arg#--name=}" ;;
    --image=*) IMAGE="${arg#--image=}" ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--with-code-server] [--name=<name>] [--image=<image>]

Creates a distrobox container and installs common development packages.

Options:
  --with-code-server   Also install code-server inside the container (optional)
  --name=<name>        Container name (default: dev-fedora-42)
  --image=<image>      Base image (default: registry.fedoraproject.org/fedora:42)
EOF
      exit 0 ;;
  esac
done

if ! command -v distrobox &>/dev/null; then
  echo "distrobox is not installed. Install it on your host first: https://github.com/89luca89/distrobox"
  exit 1
fi

# Create container if it doesn't exist
if distrobox list | grep -q "^${CONTAINER_NAME}\b"; then
  echo "Container ${CONTAINER_NAME} already exists. Skipping creation."
else
  echo "Creating distrobox container ${CONTAINER_NAME} from ${IMAGE}..."
  distrobox create --name "${CONTAINER_NAME}" --image "${IMAGE}" --yes
fi

echo "Installing development packages inside ${CONTAINER_NAME}..."

distrobox enter "${CONTAINER_NAME}" -- dnf install -y \
  golang \
  python3 python3-pip \
  nodejs npm \
  make \
  gpg \
  openssh-clients \
  which \
  procps-ng \
  git || true

if [ "$INSTALL_CODE_SERVER" -eq 1 ]; then
  echo "Installing code-server inside the container..."
  distrobox enter "${CONTAINER_NAME}" -- bash -lc '
    curl -fsSL https://code-server.dev/install.sh | sh
  '
fi

cat <<EOF
Done.

Enter the container with:
  distrobox enter ${CONTAINER_NAME}

Notes:
- Bind your project directory when creating or use shared home to access code.
- For GUI apps, ensure you allow Wayland/X11 sockets in your distrobox configuration.
- Consider configuring code-server with a password or reverse proxy if exposing to network.
EOF
