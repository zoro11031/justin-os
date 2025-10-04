#!/usr/bin/env bash
set -euo pipefail

for homedir in /var/home/*; do
    if [ -d "$homedir/.cert" ]; then
        chcon -R -t home_cert_t "$homedir/.cert" 2>/dev/null || true
    fi
done