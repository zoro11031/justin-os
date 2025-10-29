#!/usr/bin/env bash
set -euo pipefail

KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
KEY_PATH="/etc/pki/rpm-gpg/MICROSOFT.asc"
TMP_KEY="$(mktemp)"
RETRIES="${MICROSOFT_KEY_RETRIES:-5}"
SLEEP_SECONDS="${MICROSOFT_KEY_SLEEP_SECONDS:-5}"
EXPECTED_FINGERPRINT="BC528686B50D79E339D3721CEB3E94ADBE1229CF"
LONG_KEY_ID="${EXPECTED_FINGERPRINT: -16}"
RPM_PACKAGE_KEY_ID="${LONG_KEY_ID:0:8}"
RPM_PACKAGE_KEY_ID_LOWER="${RPM_PACKAGE_KEY_ID,,}"
FALLBACK_TMP=""

FALLBACK_KEY=$(cat <<'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: BSN Pgp v1.1.0.0

mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT
LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV
7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag
OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j
H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr
M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs
ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATQEEwEI
AB4FAlYxWIwCGwMGCwkIBwMCAxUIAwMWAgECHgECF4AACgkQ6z6Urb4SKc+P9gf/
diY2900wvWEgV7iMgrtGzx79W/PbwWiOkKoD9sdzhARXWiP8Q5teL/t5TUH6TZ3B
ENboDjwr705jLLPwuEDtPI9jz4kvdT86JwwG6N8gnWM8Ldi56SdJEtXrzwtlB/Fe
6tyfMT1E/PrJfgALUG9MWTIJkc0GhRJoyPpGZ6YWSLGXnk4c0HltYKDFR7q4wtI8
4cBu4mjZHZbxIO6r8Cci+xxuJkpOTIpr4pdpQKpECM6x5SaT2gVnscbN0PE19KK9
nPsBxyK4wW0AvAhed2qldBPTipgzPhqB2gu0jSryil95bKrSmlYJd1Y1XfNHno5D
xfn5JwgySBIdWWvtOI05gw==
=zPfd
-----END PGP PUBLIC KEY BLOCK-----
EOF
)

cleanup() {
  rm -f "$TMP_KEY"
  if [[ -n "$FALLBACK_TMP" ]]; then
    rm -f "$FALLBACK_TMP"
  fi
}
trap cleanup EXIT

fingerprint_for() {
  local key_file="$1"
  gpg --with-colons --show-keys "$key_file" | awk -F: '/^fpr:/ {print toupper($10); exit}'
}

ensure_key_file_matches() {
  local key_file="$1"

  if [[ ! -f "$key_file" ]]; then
    return 1
  fi

  local fingerprint
  fingerprint="$(fingerprint_for "$key_file")"

  if [[ -z "$fingerprint" ]]; then
    return 1
  fi

  [[ "$fingerprint" == "$EXPECTED_FINGERPRINT" ]]
}

install_key_from() {
  local source_file="$1"
  local fingerprint
  fingerprint="$(fingerprint_for "$source_file")"

  if [[ -z "$fingerprint" ]]; then
    echo "Unable to read fingerprint from $source_file" >&2
    return 1
  fi

  if [[ "$fingerprint" != "$EXPECTED_FINGERPRINT" ]]; then
    echo "Unexpected Microsoft GPG fingerprint: $fingerprint" >&2
    return 1
  fi

  install -Dm0644 "$source_file" "$KEY_PATH"
  rpm --import "$KEY_PATH"
}

# RPM stores imported keys as pseudo-packages named gpg-pubkey-<keyid> where
# <keyid> is the first 8 hex characters of the long (64-bit) key identifier.
# Deriving the value from the fingerprint keeps the expectation centralized.
if rpm -qa gpg-pubkey | grep -qi "$RPM_PACKAGE_KEY_ID_LOWER"; then
  if ensure_key_file_matches "$KEY_PATH"; then
    echo "Microsoft GPG key already installed; skipping download."
    exit 0
  fi

  echo "Microsoft GPG key present but ${KEY_PATH} missing or outdated; reinstalling." >&2
fi

attempt=1
while (( attempt <= RETRIES )); do
  if curl -fsSL "$KEY_URL" -o "$TMP_KEY" && install_key_from "$TMP_KEY"; then
    echo "Microsoft GPG key installed successfully."
    exit 0
  fi

  echo "Attempt $attempt to download Microsoft GPG key failed." >&2
  if (( attempt < RETRIES )); then
    sleep "$SLEEP_SECONDS"
  fi
  ((attempt++))
done
echo "All download attempts failed; using embedded Microsoft GPG key fallback." >&2

if ! FALLBACK_TMP="$(mktemp)"; then
  echo "ERROR: Unable to create temporary file for embedded Microsoft GPG key." >&2
  exit 1
fi

if ! printf '%s' "$FALLBACK_KEY" >"$FALLBACK_TMP"; then
  echo "ERROR: Unable to write embedded Microsoft GPG key to temporary file." >&2
  exit 1
fi

if install_key_from "$FALLBACK_TMP"; then
  echo "Microsoft GPG key installed from embedded fallback." >&2
  exit 0
fi

echo "ERROR: Embedded Microsoft GPG key did not match expected fingerprint." >&2
exit 1
