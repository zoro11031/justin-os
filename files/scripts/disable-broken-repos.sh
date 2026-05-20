#!/usr/bin/env bash
set -euo pipefail

# Disable repositories that are known to be broken or return 404
# in specific base images, so they don't block rpm-ostree operations.

for repo_file in /etc/yum.repos.d/*.repo; do
  [ -e "$repo_file" ] || continue

  # negativo17 multimedia repo is frequently broken on new Fedora releases
  if grep -qi "negativo17" "$repo_file" && grep -qi "multimedia" "$repo_file"; then
    if grep -q "^enabled=1" "$repo_file"; then
      echo "Disabling broken repo: $(basename "$repo_file")"
      sed -i 's/^enabled=1$/enabled=0/' "$repo_file"
    fi
  fi
done

echo "Broken-repo check complete."
