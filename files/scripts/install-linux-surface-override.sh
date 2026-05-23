#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://pkg.surfacelinux.com/fedora/linux-surface.repo"
REPO_FILE="/etc/yum.repos.d/linux-surface.repo"
RETRY_COUNT="${SURFACE_RETRY_COUNT:-5}"
RETRY_DELAY="${SURFACE_RETRY_DELAY:-10}"
RELEASE_API_URL="https://api.github.com/repos/linux-surface/linux-surface/releases/latest"
GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
AUTH_SCHEME="token"

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

CURL_ARGS=(--retry "${RETRY_COUNT}" --retry-delay "${RETRY_DELAY}" --connect-timeout 10 --max-time 60 -fLsS)
if [[ -n "${GITHUB_TOKEN}" ]]; then
  if ! RELEASE_JSON="$(curl "${CURL_ARGS[@]}" -H "Authorization: ${AUTH_SCHEME} ${GITHUB_TOKEN}" "${RELEASE_API_URL}")"; then
    echo "Failed to fetch linux-surface release metadata from ${RELEASE_API_URL}" >&2
    exit 1
  fi
else
  if ! RELEASE_JSON="$(curl "${CURL_ARGS[@]}" "${RELEASE_API_URL}")"; then
    echo "Failed to fetch linux-surface release metadata from ${RELEASE_API_URL}" >&2
    exit 1
  fi
fi

KERNEL_PATTERN="kernel-[0-9]+[^/]*\\.surface\\.fc${OS_VERSION}\\.x86_64\\.rpm$"
if command -v jq >/dev/null 2>&1; then
  KERNEL_URL="$(
    printf '%s' "${RELEASE_JSON}" \
      | jq -r --arg pattern "${KERNEL_PATTERN}" \
        '.assets[].browser_download_url | select(test($pattern))' \
      | head -n1
  )"
else
  # Fallback for minimal images without jq available.
  KERNEL_URL="$(
    printf '%s' "${RELEASE_JSON}" \
      | grep -Eo '"browser_download_url":\s*"[^"]+"' \
      | cut -d'"' -f4 \
      | grep -E "${KERNEL_PATTERN}" \
      | head -n1
  )"
fi

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
if ! rpm-ostree override replace "./${KERNEL_FILENAME}" \
  --remove kernel-core \
  --remove kernel-modules \
  --remove kernel-modules-extra \
  --remove libwacom \
  --remove libwacom-data \
  --install kernel-surface \
  --install iptsd \
  --install libwacom-surface \
  --install libwacom-surface-data; then
  echo "Failed to apply linux-surface kernel override via rpm-ostree" >&2
  exit 1
fi
popd >/dev/null

if ! rpm-ostree install kernel-surface-default-watchdog thermald; then
  echo "Failed to install linux-surface companion packages" >&2
  exit 1
fi

if ! rpm-ostree install surface-secureboot; then
  echo "Failed to install surface-secureboot" >&2
  exit 1
fi
