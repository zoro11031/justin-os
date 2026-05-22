#!/usr/bin/env bash
set -euo pipefail

# Disable repositories that are known to be broken or return 404
# in specific base images, so they don't block rpm-ostree operations.

for repo_dir in /etc/yum.repos.d /usr/etc/yum.repos.d; do
  [ -d "$repo_dir" ] || continue

  for repo_file in "$repo_dir"/*.repo; do
    [ -e "$repo_file" ] || continue

    # negativo17 multimedia repo is frequently broken on new Fedora releases.
    # Remove the .repo suffix so rpm-ostree cannot load it during metadata refreshes.
    if grep -qi "negativo17" "$repo_file" && grep -qi "multimedia" "$repo_file"; then
      echo "Disabling broken repo: $(basename "$repo_file")"
      sed -i -E 's/^[[:space:]]*enabled[[:space:]]*=[[:space:]]*1[[:space:]]*$/enabled=0/I' "$repo_file"
      sed -i -E 's/^[[:space:]]*enabled_metadata[[:space:]]*=[[:space:]]*1[[:space:]]*$/enabled_metadata=0/I' "$repo_file"
      mv -f "$repo_file" "${repo_file}.disabled"
    fi
  done
done

echo "Broken-repo check complete."
