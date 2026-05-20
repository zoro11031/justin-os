#!/usr/bin/env bash
set -euo pipefail

: "${GROUP_FILE:=/usr/lib/group}"

ensure_group() {
  local name="$1"
  local gid="$2"

  if grep -qE "^${name}:" "${GROUP_FILE}"; then
    echo "Group ${name} already present in ${GROUP_FILE}; skipping."
    return
  fi

  if grep -qE "^[^:]+:[^:]*:${gid}:" "${GROUP_FILE}"; then
    echo "ERROR: GID ${gid} is already present in ${GROUP_FILE}; refusing to add ${name}." >&2
    exit 1
  fi

  printf '%s:x:%s:\n' "${name}" "${gid}" >> "${GROUP_FILE}"
  echo "Added ${name} group to ${GROUP_FILE}."
}

ensure_group wireshark 964
ensure_group usbmon 956
