#!/usr/bin/env bash
set -euo pipefail

# Disable repositories that are known to be broken or return 404
# in specific base images, so they don't block rpm-ostree operations.

for repo_file in /etc/yum.repos.d/*.repo; do
  [ -e "$repo_file" ] || continue

  # negativo17 multimedia repo is frequently broken on new Fedora releases.
  # We must also clear enabled_metadata=1 because rpm-ostree still refreshes
  # metadata for disabled repos when that flag is set, and a 404 aborts the transaction.
  if grep -qi "negativo17" "$repo_file" && grep -qi "multimedia" "$repo_file"; then
    echo "Disabling broken repo: $(basename "$repo_file")"
    sed -i 's/^enabled=1$/enabled=0/' "$repo_file"
    sed -i 's/^enabled_metadata=1$/enabled_metadata=0/' "$repo_file"
  fi
done

echo "Broken-repo check complete."
