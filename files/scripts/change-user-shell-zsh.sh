#!/bin/sh
# Change shell to zsh for all existing users on first boot
# Runs once per deployment using a stamp file
# POSIX-compliant for dash

set -e

STAMP_FILE="/var/lib/justin-os/user-shell-changed"

# Check if already run for this deployment
if [ -f "$STAMP_FILE" ]; then
    CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
    CHANGED_DEPLOYMENT=$(cat "$STAMP_FILE")
    
    if [ "$CURRENT_DEPLOYMENT" = "$CHANGED_DEPLOYMENT" ]; then
        # Exit silently to avoid notifications
        exit 0
    fi
fi

echo "Changing user shells to zsh..."

# Change shell for all regular users (UID >= 1000, not nfsnobody)
while IFS=: read -r username _ uid _ _ homedir shell; do
    # Skip if UID < 1000 (system users)
    if [ "$uid" -lt 1000 ]; then
        continue
    fi
    
    # Skip nfsnobody and other special accounts
    if [ "$username" = "nfsnobody" ] || [ "$username" = "nobody" ]; then
        continue
    fi
    
    # Skip if home directory doesn't exist or isn't under /home or /var/home
    # POSIX-compliant pattern matching instead of bash regex
    case "$homedir" in
        /home/*|/var/home/*)
            # Valid home directory, continue
            ;;
        *)
            # Invalid, skip
            continue
            ;;
    esac
    
    # Skip if already using zsh
    if [ "$shell" = "/usr/bin/zsh" ] || [ "$shell" = "/bin/zsh" ]; then
        echo "User $username already uses zsh, skipping"
        continue
    fi
    
    # Change the shell
    if chsh -s /usr/bin/zsh "$username" 2>/dev/null; then
        echo "✓ Changed shell for $username from $shell to /usr/bin/zsh"
    else
        echo "✗ Failed to change shell for $username"
    fi
done < /etc/passwd

# Mark this deployment as complete
STAMP_DIR="${STAMP_FILE%/*}"
mkdir -p "$STAMP_DIR"
CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
echo "$CURRENT_DEPLOYMENT" > "$STAMP_FILE"

echo "User shell changes complete!"
