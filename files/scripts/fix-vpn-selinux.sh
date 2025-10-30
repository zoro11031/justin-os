#!/bin/sh
set -e

# Fix VPN certificate SELinux context permanently using semanage
# This survives reboots unlike chcon
# POSIX-compliant for dash

# Check if SELinux is enabled
if ! command -v getenforce >/dev/null 2>&1; then
    echo "SELinux tools not found, skipping VPN certificate context fix"
    exit 0
fi

if [ "$(getenforce 2>/dev/null || echo Disabled)" = "Disabled" ]; then
    echo "SELinux is disabled, skipping VPN certificate context fix"
    exit 0
fi

# Check if semanage is available
if ! command -v semanage >/dev/null 2>&1; then
    echo "Warning: semanage command not found (install policycoreutils-python-utils)"
    echo "Falling back to temporary chcon fix..."
    
    # Fallback to chcon if semanage not available
    for homedir in /var/home/*; do
        # Skip if glob didn't match anything
        [ -e "$homedir" ] || continue

        if [ -d "$homedir/.cert" ]; then
            echo "Processing $homedir/.cert"
            chcon -R -t home_cert_t "$homedir/.cert" 2>/dev/null || true
            echo "Applied temporary SELinux fix to $homedir/.cert"
        fi
        
        # Also handle NetworkManager certificate store used by Plasma
        nm_cert_path="$homedir/.local/share/networkmanagement/certificates/nm-openvpn"
        if [ -d "$nm_cert_path" ]; then
            echo "Processing $nm_cert_path"
            chcon -R -t home_cert_t "$nm_cert_path" 2>/dev/null || true
            echo "Applied temporary SELinux fix to $nm_cert_path"
        fi
    done
    exit 0
fi

echo "Setting up permanent SELinux context for VPN certificates..."

# Add permanent SELinux file context rules for all users' .cert directories
for homedir in /var/home/*; do
    # Skip if glob didn't match anything
    [ -e "$homedir" ] || continue
    
    if [ -d "$homedir" ]; then
        username="${homedir##*/}"
        cert_path="$homedir/.cert"
        
        # Add SELinux file context rule if .cert directory exists
        if [ -d "$cert_path" ]; then
            echo "Processing $cert_path"
            echo "Adding SELinux rule for $cert_path"
            
            # Try to add, if it exists, modify it
            if semanage fcontext -l | grep -q "^${cert_path}"; then
                semanage fcontext -m -t home_cert_t "${cert_path}(/.*)?" 2>/dev/null || true
            else
                semanage fcontext -a -t home_cert_t "${cert_path}(/.*)?" 2>/dev/null || true
            fi
            
            # Apply the context
            restorecon -Rv "$cert_path" 2>/dev/null || true
            echo "✓ Fixed SELinux context for $username's VPN certificates"
        fi
        
        # Also handle NetworkManager certificate store used by Plasma
        nm_cert_path="$homedir/.local/share/networkmanagement/certificates/nm-openvpn"
        if [ -d "$nm_cert_path" ]; then
            echo "Processing $nm_cert_path"
            echo "Adding SELinux rule for $nm_cert_path"
            
            # Try to add, if it exists, modify it
            # Use grep -F for literal string matching to avoid regex issues
            if semanage fcontext -l | grep -F "${nm_cert_path}"; then
                semanage fcontext -m -t home_cert_t "${nm_cert_path}(/.*)?" 2>/dev/null || true
            else
                semanage fcontext -a -t home_cert_t "${nm_cert_path}(/.*)?" 2>/dev/null || true
            fi
            
            # Apply the context
            restorecon -Rv "$nm_cert_path" 2>/dev/null || true
            echo "✓ Fixed SELinux context for $username's NetworkManager VPN certificates"
        fi
    fi
done

# Also set a general rule for any future .cert directories
echo "Adding general SELinux rule for all /var/home/*/.cert directories"
GENERAL_RULE="/var/home/[^/]+/.cert(/.*)?"

# Check if general rule already exists
if semanage fcontext -l | grep -q "/var/home/\["; then
    echo "General rule already exists, updating..."
    semanage fcontext -m -t home_cert_t "$GENERAL_RULE" 2>/dev/null || true
else
    semanage fcontext -a -t home_cert_t "$GENERAL_RULE" 2>/dev/null || true
fi

# Also set a general rule for NetworkManager certificate directories
echo "Adding general SELinux rule for NetworkManager certificate directories"
NM_GENERAL_RULE="/var/home/[^/]+/.local/share/networkmanagement/certificates/nm-openvpn(/.*)?"

# Check if NetworkManager general rule already exists with more specific pattern
if semanage fcontext -l | grep -F "/var/home/[^/]+/.local/share/networkmanagement/certificates/nm-openvpn"; then
    echo "NetworkManager general rule already exists, updating..."
    semanage fcontext -m -t home_cert_t "$NM_GENERAL_RULE" 2>/dev/null || true
else
    semanage fcontext -a -t home_cert_t "$NM_GENERAL_RULE" 2>/dev/null || true
fi

echo "SELinux VPN certificate fix complete and permanent!"
