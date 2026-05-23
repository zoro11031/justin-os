#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://pkg.surfacelinux.com/fedora/linux-surface.repo"
REPO_FILE="/etc/yum.repos.d/linux-surface.repo"
RETRY_COUNT="${SURFACE_RETRY_COUNT:-5}"
RETRY_DELAY="${SURFACE_RETRY_DELAY:-10}"
RELEASE_API_URL="https://api.github.com/repos/linux-surface/linux-surface/releases/latest"

install -d -m0755 "$(dirname "${REPO_FILE}")"
if ! curl --retry "${RETRY_COUNT}" --retry-delay "${RETRY_DELAY}" --connect-timeout 10 --max-time 60 -fLsS \
  -o "${REPO_FILE}" "${REPO_URL}"; then
  echo "Failed to download linux-surface repo file from ${REPO_URL}" >&2
  exit 1
fi

OS_VERSION="${OS_VERSION:-}"
if [[ -z "${OS_VERSION}" ]]; then
  if ! OS_VERSION="$(rpm -E %fedora)"; then
    echo "Unable to determine Fedora version via rpm -E %fedora" >&2
    exit 1
  fi
fi

if [[ -z "${OS_VERSION}" ]]; then
  echo "Fedora version is empty; cannot resolve linux-surface assets" >&2
  exit 1
fi

if ! RELEASE_JSON="$(curl --retry "${RETRY_COUNT}" --retry-delay "${RETRY_DELAY}" --connect-timeout 10 --max-time 60 -fLsS "${RELEASE_API_URL}")"; then
  echo "Failed to fetch linux-surface release metadata from ${RELEASE_API_URL}" >&2
  exit 1
fi
KERNEL_URL="$(
  printf '%s' "${RELEASE_JSON}" \
    | grep -Eo '"browser_download_url":\s*"[^"]+"' \
    | cut -d'"' -f4 \
    | grep -E "kernel-[0-9][^/]*\\.surface\\.fc${OS_VERSION}\\.x86_64\\.rpm" \
    | head -n1
)"

if [[ -z "${KERNEL_URL}" ]]; then
  echo "Unable to locate linux-surface dummy kernel RPM for Fedora ${OS_VERSION}" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

KERNEL_FILENAME="${KERNEL_URL##*/}"
if ! curl --retry "${RETRY_COUNT}" --retry-delay "${RETRY_DELAY}" --connect-timeout 10 --max-time 300 -fL \
  -o "${TMP_DIR}/${KERNEL_FILENAME}" "${KERNEL_URL}"; then
  echo "Failed to download linux-surface dummy kernel RPM from ${KERNEL_URL}" >&2
  exit 1
fi

pushd "${TMP_DIR}" >/dev/null
rpm-ostree override replace "./${KERNEL_FILENAME}" \
  --remove kernel-core \
  --remove kernel-modules \
  --remove kernel-modules-extra \
  --remove libwacom \
  --remove libwacom-data \
  --install kernel-surface \
  --install iptsd \
  --install libwacom-surface \
  --install libwacom-surface-data
popd >/dev/null

rpm-ostree install kernel-surface-default-watchdog thermald
rpm-ostree install surface-secureboot
