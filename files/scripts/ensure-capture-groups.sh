#!/usr/bin/env bash
set -euo pipefail

log() {
  printf 'ensure-capture-groups: %s\n' "$*"
}

die() {
  printf 'ensure-capture-groups: ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command '$1' is not available."
}

group_name_from_entry() {
  local entry="$1"
  local name

  IFS=: read -r name _ <<< "${entry}"
  printf '%s\n' "${name}"
}

group_gid_from_entry() {
  local entry="$1"
  local gid

  IFS=: read -r _ _ gid _ <<< "${entry}"
  printf '%s\n' "${gid}"
}

lookup_group_by_name() {
  local name="$1"

  getent group "${name}" 2>/dev/null || true
}

lookup_group_by_gid() {
  local gid="$1"
  local entry

  if entry="$(getent group "${gid}" 2>/dev/null)"; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "$(group_gid_from_entry "${line}")" == "${gid}" ]] || continue
      printf '%s\n' "${line}"
      return 0
    done <<< "${entry}"
  fi

  getent group | awk -F: -v gid="${gid}" '
    $3 == gid {
      print
      found = 1
      exit
    }
    END {
      exit found ? 0 : 1
    }
  '
}

find_available_gid() {
  getent group | awk -F: '
    $3 ~ /^[0-9]+$/ {
      used[$3] = 1
    }
    END {
      for (gid = 1000; gid <= 60000; gid++) {
        if (!(gid in used)) {
          print gid
          exit 0
        }
      }
      exit 1
    }
  '
}

ensure_group_exists_after_add() {
  local name="$1"
  local entry

  entry="$(lookup_group_by_name "${name}")"
  [[ -n "${entry}" ]] || die "groupadd reported success, but '${name}' is still not visible through getent."

  log "Group '${name}' is present with GID $(group_gid_from_entry "${entry}")."
}

add_group_with_preferred_gid() {
  local name="$1"
  local gid="$2"

  if groupadd -g "${gid}" "${name}"; then
    log "Created group '${name}' with preferred GID ${gid}."
    ensure_group_exists_after_add "${name}"
    return
  fi

  if [[ -n "$(lookup_group_by_name "${name}")" ]]; then
    log "Group '${name}' appeared while adding it; treating as success."
    return
  fi

  log "groupadd could not create '${name}' with preferred GID ${gid}; retrying without a fixed GID."
  groupadd "${name}" || die "Failed to create group '${name}' with automatic GID allocation."
  ensure_group_exists_after_add "${name}"
}

add_group_with_automatic_gid() {
  local name="$1"
  local selected_gid

  selected_gid="$(find_available_gid || true)"
  if [[ -n "${selected_gid}" ]]; then
    log "Selected available GID ${selected_gid} for '${name}' from current getent group data."
    if groupadd -g "${selected_gid}" "${name}"; then
      log "Created group '${name}' with selected GID ${selected_gid}."
      ensure_group_exists_after_add "${name}"
      return
    fi

    if [[ -n "$(lookup_group_by_name "${name}")" ]]; then
      log "Group '${name}' appeared while adding it; treating as success."
      return
    fi

    log "groupadd could not create '${name}' with selected GID ${selected_gid}; retrying without a fixed GID."
  else
    log "No available GID found in the preferred search ranges; retrying '${name}' without a fixed GID."
  fi

  if groupadd "${name}"; then
    log "Created group '${name}' with groupadd automatic GID allocation."
    ensure_group_exists_after_add "${name}"
    return
  fi

  if [[ -n "$(lookup_group_by_name "${name}")" ]]; then
    log "Group '${name}' appeared while adding it; treating as success."
    return
  fi

  die "Failed to create group '${name}' with groupadd automatic GID allocation."
}

ensure_group() {
  local name="$1"
  local gid="$2"
  local existing_entry
  local gid_entry
  local gid_owner

  existing_entry="$(lookup_group_by_name "${name}")"
  if [[ -n "${existing_entry}" ]]; then
    log "Group '${name}' already exists with GID $(group_gid_from_entry "${existing_entry}"); skipping."
    return
  fi

  gid_entry="$(lookup_group_by_gid "${gid}" || true)"
  if [[ -n "${gid_entry}" ]]; then
    gid_owner="$(group_name_from_entry "${gid_entry}")"
    if [[ "${gid_owner}" == "${name}" ]]; then
      log "Preferred GID ${gid} already belongs to '${name}'; treating as success."
      return
    fi

    log "Preferred GID ${gid} for '${name}' is already used by '${gid_owner}'; creating '${name}' with an automatic GID."
    add_group_with_automatic_gid "${name}"
    return
  fi

  add_group_with_preferred_gid "${name}" "${gid}"
}

require_command getent
require_command groupadd
require_command awk

ensure_group wireshark 964
ensure_group usbmon 956
