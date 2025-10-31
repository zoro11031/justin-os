#!/bin/bash
# Setup Fedora distrobox for development with common tools and SDKs
# This script creates a development container using the latest Fedora toolbox image
# and installs essential development tools, languages, and utilities.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="${DISTROBOX_NAME:-fedora-toolbox}"
TOOLBOX_IMAGE="${TOOLBOX_IMAGE:-ghcr.io/ublue-os/fedora-toolbox:latest}"
INSTALL_MINIMAL="${INSTALL_MINIMAL:-false}"

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create and configure a Fedora distrobox for development with common tools and SDKs.

Options:
    -n, --name NAME         Container name (default: fedora-toolbox)
    -i, --image IMAGE       Toolbox image (default: ghcr.io/ublue-os/fedora-toolbox:latest)
    --minimal               Install only essential tools (skip optional SDKs)
    -h, --help              Show this help message

Environment Variables:
    DISTROBOX_NAME          Alternative way to set container name
    TOOLBOX_IMAGE           Alternative way to set toolbox image

Examples:
    # Create default container with all tools
    $(basename "$0")

    # Create container with custom name
    $(basename "$0") --name my-dev-box

    # Minimal installation without optional SDKs
    $(basename "$0") --minimal

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -i|--image)
            TOOLBOX_IMAGE="$2"
            shift 2
            ;;
        --minimal)
            INSTALL_MINIMAL="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if distrobox is available
if ! command -v distrobox &> /dev/null; then
    error "distrobox is not installed. Please install it first."
    exit 1
fi

# Check if container already exists
if distrobox list | grep -q "^${CONTAINER_NAME}"; then
    warn "Container '${CONTAINER_NAME}' already exists."
    read -p "Do you want to remove it and create a new one? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Removing existing container..."
        distrobox rm -f "${CONTAINER_NAME}"
    else
        info "Entering existing container for setup..."
        exec distrobox enter "${CONTAINER_NAME}"
    fi
fi

# Create the distrobox
info "Creating distrobox '${CONTAINER_NAME}' using image '${TOOLBOX_IMAGE}'..."
distrobox create \
    --name "${CONTAINER_NAME}" \
    --image "${TOOLBOX_IMAGE}" \
    --yes

success "Container '${CONTAINER_NAME}' created successfully!"

# Run the setup script inside the container
info "Running setup inside the container..."
distrobox enter "${CONTAINER_NAME}" -- env \
    INSTALL_MINIMAL="${INSTALL_MINIMAL}" \
    CONTAINER_NAME="${CONTAINER_NAME}" \
    bash <<'INNER_SCRIPT'
#!/bin/bash
set -euo pipefail

INSTALL_MINIMAL="${INSTALL_MINIMAL:-false}"

# Normalize booleans for comparison
to_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}
INSTALL_MINIMAL="$(to_lower "${INSTALL_MINIMAL}")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

ensure_path_prefix() {
    local dir="$1"
    if [[ -d "$dir" && ":${PATH}:" != *":${dir}:"* ]]; then
        PATH="${dir}:${PATH}"
    fi
}

ensure_path_suffix() {
    local dir="$1"
    if [[ -d "$dir" && ":${PATH}:" != *":${dir}:"* ]]; then
        PATH="${PATH}:${dir}"
    fi
}

info "Updating system packages..."
sudo dnf update -y

info "Enabling RPM Fusion repositories..."
FEDORA_RELEASE="$(rpm -E %fedora)"
RPMFUSION_FREE="rpmfusion-free-release-${FEDORA_RELEASE}"
RPMFUSION_NONFREE="rpmfusion-nonfree-release-${FEDORA_RELEASE}"

enable_rpmfusion_release() {
    local package_name="$1"
    local url="$2"
    if rpm -q "${package_name}" &> /dev/null; then
        info "${package_name} already installed."
        return 0
    fi

    if sudo dnf install -y "${url}"; then
        success "Enabled ${package_name}."
        return 0
    fi

    warn "Failed to enable ${package_name}; repository-dependent packages may be skipped."
    return 1
}

enable_rpmfusion_release "${RPMFUSION_FREE}" \
    "https://download1.rpmfusion.org/free/fedora/${RPMFUSION_FREE}.noarch.rpm"
enable_rpmfusion_release "${RPMFUSION_NONFREE}" \
    "https://download1.rpmfusion.org/nonfree/fedora/${RPMFUSION_NONFREE}.noarch.rpm"

sudo dnf makecache -y

info "Installing base development tools..."
dnf_package_available() {
    local package_name="$1"
    if sudo dnf list --installed "${package_name}" &> /dev/null; then
        return 0
    fi

    sudo dnf list --available "${package_name}" &> /dev/null
}

install_package_group() {
    local description="$1"
    shift
    local packages=("$@")
    local total=${#packages[@]}
    local installed=0
    local skipped=0

    for package in "${packages[@]}"; do
        if rpm -q "${package}" &> /dev/null; then
            ((installed++))
            continue
        fi

        if dnf_package_available "${package}"; then
            if sudo dnf install -y "${package}"; then
                ((installed++))
            else
                warn "Failed to install package '${package}'; skipping."
                ((skipped++))
            fi
        else
            warn "Package '${package}' is not available in enabled repositories; skipping."
            ((skipped++))
        fi
    done

    if (( skipped == 0 )); then
        success "${description} installed!"
    else
        info "${description}: installed ${installed}/${total} packages (skipped ${skipped})."
    fi
}

list_present_commands() {
    local commands=("$@")
    local present=()
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            present+=("$cmd")
        fi
    done

    if (( ${#present[@]} == 0 )); then
        printf 'none'
    else
        local IFS=', '
        printf '%s' "${present[*]}"
    fi
}

BASE_PACKAGES=(
    automake
    autoconf
    bat
    btop
    bzip2
    cmake
    curl
    diffutils
    dnf-plugins-core
    fd-find
    fontconfig
    gcc
    gcc-c++
    git
    git-lfs
    gzip
    htop
    jq
    libtool
    make
    nano
    ncdu
    patch
    pkgconf-pkg-config
    ripgrep
    screen
    tar
    tmux
    tree
    unzip
    vim-enhanced
    wget
    xz
)

install_package_group "Base development tools" "${BASE_PACKAGES[@]}"

# Install JetBrains Mono Nerd Font
info "Installing JetBrains Mono Nerd Font..."
if command -v fc-list &> /dev/null && fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    success "JetBrains Mono Nerd Font already installed"
else
    if ! command -v fc-list &> /dev/null; then
        install_package_group "fontconfig utilities" fontconfig
    fi

    TMP_FONT_DIR="$(mktemp -d)"
    FONT_ARCHIVE="${TMP_FONT_DIR}/JetBrainsMono.zip"
    FONT_EXTRACT_DIR="${TMP_FONT_DIR}/JetBrainsMono"
    FONT_INSTALL_DIR="${HOME}/.local/share/fonts/JetBrainsMono-Nerd-Font"

    if ! curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "${FONT_ARCHIVE}"; then
        echo -e "${RED}[ERROR]${NC} Failed to download JetBrains Mono Nerd Font archive."
        rm -rf "${TMP_FONT_DIR}"
        exit 1
    fi
    if ! unzip -q "${FONT_ARCHIVE}" -d "${FONT_EXTRACT_DIR}"; then
        echo -e "${RED}[ERROR]${NC} Failed to extract JetBrains Mono Nerd Font archive. The file may be corrupted."
        rm -rf "${TMP_FONT_DIR}"
        exit 1
    fi

    mkdir -p "${FONT_INSTALL_DIR}"
    shopt -s nullglob
    for font_file in "${FONT_EXTRACT_DIR}"/*.ttf "${FONT_EXTRACT_DIR}"/*.otf; do
        install -Dm644 "${font_file}" "${FONT_INSTALL_DIR}/$(basename "${font_file}")"
    done
    shopt -u nullglob

    fc-cache -f "${HOME}/.local/share/fonts"
    rm -rf "${TMP_FONT_DIR}"
    success "JetBrains Mono Nerd Font installed!"
fi

install_package_group "Shell navigation tools" fzf zoxide

if [[ "${INSTALL_MINIMAL}" != "true" ]]; then
    info "Installing language SDKs and runtimes..."

    # Python
    info "Installing Python development environment..."
    install_package_group "Python build dependencies" \
        python3 \
        python3-pip \
        python3-devel \
        python3-setuptools \
        python3-wheel \
        python3-virtualenv \
        pipx

    if command -v pipx &> /dev/null; then
        mkdir -p "${HOME}/.local/bin"
        ensure_path_prefix "${HOME}/.local/bin"
        export PATH

        # Install common Python tools via pipx (idempotent)
        PYTHON_TOOLS=(
            poetry
            black
            ruff
            mypy
            pylint
        )

        for tool in "${PYTHON_TOOLS[@]}"; do
            pipx install --force "$tool"
        done
        info "pipx-installed binaries are available for this session. Confirm ~/.local/bin is on your PATH in your own shell configuration."
        success "Python environment installed!"
    else
        warn "pipx not available; skipping Python tooling bootstrap."
    fi

    # Node.js and npm
    info "Installing Node.js and npm..."
    install_package_group "Node.js toolchain" nodejs npm

    # Install common global npm packages
    if command -v npm &> /dev/null; then
        NPM_PREFIX="${HOME}/.npm-global"
        mkdir -p "${NPM_PREFIX}"
        npm config set prefix "${NPM_PREFIX}"
        ensure_path_prefix "${NPM_PREFIX}/bin"
        export PATH

        npm install -g yarn pnpm typescript ts-node eslint prettier npm-check-updates
        info "Global npm bin directory (${NPM_PREFIX}/bin) added for this session. Update your shell configuration manually if needed."
        success "Node.js and npm installed!"
    else
        warn "npm not available; skipping global Node.js tooling install."
    fi

    # Go
    info "Installing Go..."
    install_package_group "Go toolchain" golang

    # Setup Go environment
    if command -v go &> /dev/null; then
        mkdir -p ~/go/{bin,src,pkg}
        export GOPATH="$HOME/go"
        ensure_path_suffix "${GOPATH}/bin"
        export PATH

        # Install common Go tools
        go install golang.org/x/tools/gopls@latest
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        go install honnef.co/go/tools/cmd/staticcheck@latest
        info "Go workspace configured for this session. Add ${GOPATH}/bin to your shell PATH manually if not already present."
        success "Go installed!"
    else
        warn "Go compiler not available; skipping Go workspace configuration."
    fi

    # Rust
    info "Installing Rust..."
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env"

        # Install common Rust tools
        cargo install cargo-edit
        cargo install cargo-watch
        info "Rust environment loaded for this session. Ensure ~/.cargo/bin is on your PATH in your own shell configuration."
        success "Rust installed!"
    else
        success "Rust already installed"
    fi

    # Additional development tools
    info "Installing additional development tools..."
    install_package_group "Container and debugging tools" \
        podman \
        podman-compose \
        lazygit \
        gh \
        gdb \
        valgrind \
        strace \
        ltrace
fi

info "Skipping shell profile modifications at user request. Review install summary below for any manual PATH updates."

info "Cleaning up..."
sudo dnf clean all

success "======================================"
success "Development environment setup complete!"
success "======================================"
echo ""
info "Installed tools:"
echo "  - Base: $(list_present_commands gcc g++ make cmake git curl wget)"
echo "  - CLI utils: $(list_present_commands fzf zoxide rg fd bat jq btop lazygit)"

if [[ "${INSTALL_MINIMAL}" != "true" ]]; then
    if command -v python3 &> /dev/null; then
        echo "  - Python: $(python3 --version 2>&1 | head -1)"
    else
        echo "  - Python: not installed"
    fi

    if command -v node &> /dev/null; then
        node_version="$(node --version 2>&1)"
        if command -v npm &> /dev/null; then
            echo "  - Node.js: ${node_version}, npm $(npm --version 2>&1)"
        else
            echo "  - Node.js: ${node_version} (npm not installed)"
        fi
    else
        echo "  - Node.js: not installed"
    fi

    if command -v go &> /dev/null; then
        echo "  - Go: $(go version 2>&1 | awk '{print $3}')"
    else
        echo "  - Go: not installed"
    fi

    if command -v rustc &> /dev/null; then
        echo "  - Rust: $(rustc --version 2>&1 | awk '{print $2}')"
    else
        echo "  - Rust: not installed"
    fi
fi

echo ""
info "To start using your development environment:"
echo "  1. Exit this container (type 'exit' or Ctrl+D)"
echo "  2. Enter the container: distrobox enter ${CONTAINER_NAME}"
echo "  3. Start coding!"
echo ""
info "Use 'z <directory>' instead of 'cd' for faster navigation with zoxide"
info "Use Ctrl+R for fzf history search"

INNER_SCRIPT

success "======================================"
success "Setup completed successfully!"
success "======================================"
echo ""
info "To enter your development container:"
echo "  distrobox enter ${CONTAINER_NAME}"
echo ""
info "For more information, see docs/DEV_IN_CONTAINER.md"
