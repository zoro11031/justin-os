#!/usr/bin/env bash
#
# Install dotfiles using GNU Stow
#
# Usage: ./install.sh [package1] [package2] ...
# If no packages are specified, all packages will be installed.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$DOTFILES_DIR"
TARGET_DIR="$HOME"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${RED}Error: GNU Stow is not installed.${NC}"
    echo "Please install it using your package manager:"
    echo "  - Ubuntu/Debian: sudo apt-get install stow"
    echo "  - macOS: brew install stow"
    echo "  - Arch: sudo pacman -S stow"
    exit 1
fi

# Get all package directories (directories that don't start with .)
get_packages() {
    find "$STOW_DIR" -maxdepth 1 -type d ! -path "$STOW_DIR" ! -name ".*" -exec basename {} \;
}

# Install a single package
install_package() {
    local package=$1
    echo -e "${GREEN}Installing $package...${NC}"
    
    if [ ! -d "$STOW_DIR/$package" ]; then
        echo -e "${RED}Error: Package '$package' does not exist${NC}"
        return 1
    fi
    
    cd "$STOW_DIR"
    stow -v -t "$TARGET_DIR" "$package"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $package installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install $package${NC}"
        return 1
    fi
}

# Uninstall a single package
uninstall_package() {
    local package=$1
    echo -e "${YELLOW}Uninstalling $package...${NC}"
    
    cd "$STOW_DIR"
    stow -v -D -t "$TARGET_DIR" "$package"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $package uninstalled successfully${NC}"
    else
        echo -e "${RED}✗ Failed to uninstall $package${NC}"
        return 1
    fi
}

# Reinstall a single package
reinstall_package() {
    local package=$1
    echo -e "${YELLOW}Reinstalling $package...${NC}"
    uninstall_package "$package" 2>/dev/null || true
    install_package "$package"
}

# Main installation logic
main() {
    echo "=== Dotfiles Installation ==="
    echo "Directory: $DOTFILES_DIR"
    echo "Target: $TARGET_DIR"
    echo ""
    
    # Parse command line arguments
    local mode="install"
    local packages=()
    
    for arg in "$@"; do
        case $arg in
            -u|--uninstall)
                mode="uninstall"
                ;;
            -r|--reinstall)
                mode="reinstall"
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS] [PACKAGES...]"
                echo ""
                echo "Options:"
                echo "  -u, --uninstall    Uninstall the specified packages"
                echo "  -r, --reinstall    Reinstall the specified packages"
                echo "  -h, --help         Show this help message"
                echo ""
                echo "If no packages are specified, all packages will be processed."
                echo ""
                echo "Available packages:"
                get_packages | sed 's/^/  - /'
                exit 0
                ;;
            *)
                packages+=("$arg")
                ;;
        esac
    done
    
    # If no packages specified, use all packages
    if [ ${#packages[@]} -eq 0 ]; then
        echo "No packages specified, processing all packages..."
        mapfile -t packages < <(get_packages)
    fi
    
    echo "Packages to $mode:"
    printf '  - %s\n' "${packages[@]}"
    echo ""
    
    # Process each package
    local failed=0
    for package in "${packages[@]}"; do
        case $mode in
            install)
                install_package "$package" || failed=$((failed + 1))
                ;;
            uninstall)
                uninstall_package "$package" || failed=$((failed + 1))
                ;;
            reinstall)
                reinstall_package "$package" || failed=$((failed + 1))
                ;;
        esac
        echo ""
    done
    
    # Summary
    echo "=== Summary ==="
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All packages processed successfully!${NC}"
    else
        echo -e "${RED}$failed package(s) failed to process${NC}"
        exit 1
    fi
}

main "$@"
