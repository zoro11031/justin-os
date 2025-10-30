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

BASHRC="${HOME}/.bashrc"
touch "${BASHRC}"

append_line_to_bashrc() {
    local line="$1"
    if ! grep -Fqx "$line" "${BASHRC}"; then
        echo "$line" >> "${BASHRC}"
    fi
}

append_block_to_bashrc() {
    local marker="$1"
    local closing="${marker//>>>/<<<}"
    if ! grep -Fq "$marker" "${BASHRC}"; then
        {
            echo ""
            echo "$marker"
            cat
            echo "$closing"
        } >> "${BASHRC}"
    else
        # Consume stdin so heredoc does not leak to terminal
        cat > /dev/null
    fi
}

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

info "Installing base development tools..."
BASE_PACKAGES=(
    gcc
    gcc-c++
    make
    cmake
    automake
    autoconf
    libtool
    pkg-config
    dnf-plugins-core
    git
    git-lfs
    curl
    wget
    unzip
    tar
    gzip
    bzip2
    xz
    patch
    diffutils
    fontconfig
    vim
    nano
    tmux
    screen
    htop
    btop
    ncdu
    tree
    jq
    ripgrep
    fd-find
    bat
    eza
)

BASE_PROCESSED=0
BASE_SKIPPED=0
# Attempt to install all base packages in one batch
if sudo dnf install -y "${BASE_PACKAGES[@]}"; then
    BASE_PROCESSED=${#BASE_PACKAGES[@]}
    BASE_SKIPPED=0
else
    # If batch install fails, check which packages are missing and try to install them individually
    for pkg in "${BASE_PACKAGES[@]}"; do
        if rpm -q "${pkg}" &> /dev/null; then
            ((BASE_PROCESSED++))
        else
            if sudo dnf install -y "${pkg}"; then
                ((BASE_PROCESSED++))
            else
                warn "Package '${pkg}' unavailable or failed to install; skipping."
                ((BASE_SKIPPED++))
            fi
        fi
    done
fi

if (( BASE_SKIPPED == 0 )); then
    success "Base development tools installed!"
else
    warn "Processed ${BASE_PROCESSED} packages; skipped ${BASE_SKIPPED}."
fi

# Install JetBrains Mono Nerd Font
info "Installing JetBrains Mono Nerd Font..."
if command -v fc-list &> /dev/null && fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    success "JetBrains Mono Nerd Font already installed"
else
    if ! command -v fc-list &> /dev/null; then
        info "fontconfig utilities missing; installing..."
        sudo dnf install -y fontconfig
    fi

    TMP_FONT_DIR="$(mktemp -d)"
    trap 'rm -rf "${TMP_FONT_DIR}"' EXIT
    FONT_ARCHIVE="${TMP_FONT_DIR}/JetBrainsMono.zip"
    FONT_EXTRACT_DIR="${TMP_FONT_DIR}/JetBrainsMono"
    FONT_INSTALL_DIR="${HOME}/.local/share/fonts/JetBrainsMono-Nerd-Font"

    if ! curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "${FONT_ARCHIVE}"; then
        echo -e "${RED}[ERROR]${NC} Failed to download JetBrains Mono Nerd Font archive."
        exit 1
    fi
    if ! unzip -q "${FONT_ARCHIVE}" -d "${FONT_EXTRACT_DIR}"; then
        echo -e "${RED}[ERROR]${NC} Failed to extract JetBrains Mono Nerd Font archive. The file may be corrupted."
        exit 1
    fi

    mkdir -p "${FONT_INSTALL_DIR}"
    shopt -s nullglob
    for font_file in "${FONT_EXTRACT_DIR}"/*.ttf "${FONT_EXTRACT_DIR}"/*.otf; do
        install -Dm644 "${font_file}" "${FONT_INSTALL_DIR}/$(basename "${font_file}")"
    done
    shopt -u nullglob

    fc-cache -f "${HOME}/.local/share/fonts"
    success "JetBrains Mono Nerd Font installed!"
fi

# Install fzf
info "Installing fzf..."
if ! command -v fzf &> /dev/null; then
    sudo dnf install -y fzf
    success "fzf installed!"
else
    success "fzf already installed"
fi

# Install zoxide
info "Installing zoxide..."
if ! command -v zoxide &> /dev/null; then
    sudo dnf install -y zoxide
    success "zoxide installed!"
else
    success "zoxide already installed"
fi

if [[ "${INSTALL_MINIMAL}" != "true" ]]; then
    info "Installing language SDKs and runtimes..."

    # Python
    info "Installing Python development environment..."
    sudo dnf install -y \
        python3 \
        python3-pip \
        python3-devel \
        python3-setuptools \
        python3-wheel \
        python3-virtualenv \
        pipx

    pipx ensurepath
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
    success "Python environment installed!"

    # Node.js and npm
    info "Installing Node.js and npm..."
    sudo dnf install -y nodejs npm

    # Install common global npm packages
    NPM_PREFIX="${HOME}/.npm-global"
    mkdir -p "${NPM_PREFIX}"
    npm config set prefix "${NPM_PREFIX}"
    append_line_to_bashrc 'export PATH="$HOME/.npm-global/bin:$PATH"'
    ensure_path_prefix "${NPM_PREFIX}/bin"
    export PATH

    npm install -g yarn pnpm typescript ts-node eslint prettier npm-check-updates
    success "Node.js and npm installed!"

    # Go
    info "Installing Go..."
    sudo dnf install -y golang

    # Setup Go environment
    mkdir -p ~/go/{bin,src,pkg}
    append_line_to_bashrc 'export GOPATH="$HOME/go"'
    append_line_to_bashrc 'export PATH="$PATH:$GOPATH/bin"'
    export GOPATH="$HOME/go"
    ensure_path_suffix "${GOPATH}/bin"
    export PATH

    # Install common Go tools
    go install golang.org/x/tools/gopls@latest
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    go install honnef.co/go/tools/cmd/staticcheck@latest
    success "Go installed!"

    # Rust
    info "Installing Rust..."
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env"
        append_line_to_bashrc 'source "$HOME/.cargo/env"'

        # Install common Rust tools
        cargo install cargo-edit
        cargo install cargo-watch
        success "Rust installed!"
    else
        success "Rust already installed"
    fi

    # Additional development tools
    info "Installing additional development tools..."
    if ! sudo dnf install -y docker-ce-cli; then
        warn "docker-ce-cli not available in current repos, skipping."
    fi
    sudo dnf install -y \
        podman-compose \
        lazygit \
        gh \
        gdb \
        valgrind \
        strace \
        ltrace
    success "Additional development tools installed!"
fi

# Configure shell integrations
info "Configuring shell integrations..."

# Add fzf key bindings and completion
if [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
    append_line_to_bashrc 'source /usr/share/fzf/shell/key-bindings.bash'
fi

# Add zoxide init
append_line_to_bashrc 'eval "$(zoxide init bash)"'

# Add useful aliases
append_block_to_bashrc "# >>> justin-os dev aliases >>>" <<'EOF'
# Development aliases
alias g='git'
alias dc='docker-compose'
alias pc='podman-compose'
alias k='kubectl'
alias tf='terraform'
alias v='nvim'
alias lg='lazygit'

# Modern CLI tool aliases
alias ls='eza'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias cd='z'  # zoxide

# Python aliases
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
EOF

success "Shell integrations configured!"

info "Cleaning up..."
sudo dnf clean all

success "======================================"
success "Development environment setup complete!"
success "======================================"
echo ""
info "Installed tools:"
echo "  - Base: gcc, g++, make, cmake, git, curl, wget, etc."
echo "  - CLI utils: fzf, zoxide, ripgrep, fd, bat, eza, jq, btop, lazygit"

if [[ "${INSTALL_MINIMAL}" != "true" ]]; then
    echo "  - Python: $(python3 --version 2>&1 | head -1), pip, pipx, poetry, black, ruff"
    echo "  - Node.js: $(node --version 2>&1), npm, yarn, pnpm, typescript"
    echo "  - Go: $(go version 2>&1 | awk '{print $3}')"
    echo "  - Rust: $(rustc --version 2>&1 | awk '{print $2}')"
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
