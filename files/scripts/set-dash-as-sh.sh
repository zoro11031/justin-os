#!/usr/bin/env bash
# Change system shell /bin/sh to dash
set -euo pipefail

echo "Changing /bin/sh to dash..."

# Remove the existing /bin/sh symlink (usually points to bash)
if [ -L /bin/sh ]; then
    rm -f /bin/sh
elif [ -f /bin/sh ]; then
    # If it's a regular file, back it up
    mv /bin/sh /bin/sh.backup
fi

# Create symlink to dash
ln -sf /usr/bin/dash /bin/sh

# Verify the change
if [ -L /bin/sh ] && [ "$(readlink /bin/sh)" = "/usr/bin/dash" ]; then
    echo "Successfully changed /bin/sh to dash"
    ls -l /bin/sh
else
    echo "ERROR: Failed to change /bin/sh to dash" >&2
    exit 1
fi

exit 0
