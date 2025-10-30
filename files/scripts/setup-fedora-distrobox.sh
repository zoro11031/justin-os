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
CONTAINER_NAME="${DISTROBOX_NAME:-dev-fedora}"
TOOLBOX_IMAGE="${TOOLBOX_IMAGE:-ghcr.io/ublue-os/fedora-toolbox:latest}"
INSTALL_VSCODE="${INSTALL_VSCODE:-true}"
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
    -n, --name NAME         Container name (default: dev-fedora)
    -i, --image IMAGE       Toolbox image (default: ghcr.io/ublue-os/fedora-toolbox:latest)
    --no-vscode             Skip VS Code installation
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

    # Minimal installation without VS Code
    $(basename "$0") --minimal --no-vscode

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
        --no-vscode)
            INSTALL_VSCODE="false"
            shift
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

# Generate setup script to run inside the container
SETUP_SCRIPT=$(mktemp)
cat > "${SETUP_SCRIPT}" << 'INNER_SCRIPT'
#!/bin/bash
set -euo pipefail

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

info "Updating system packages..."
sudo dnf update -y

info "Installing base development tools..."
sudo dnf install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkg-config \
    git \
    git-lfs \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz \
    patch \
    diffutils \
    vim \
    nano \
    tmux \
    screen \
    htop \
    btop \
    ncdu \
    tree \
    jq \
    ripgrep \
    fd-find \
    bat \
    eza

success "Base development tools installed!"

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

    # Install common Python tools via pipx
    pipx install poetry
    pipx install black
    pipx install ruff
    pipx install mypy
    pipx install pylint
    success "Python environment installed!"

    # Node.js and npm
    info "Installing Node.js and npm..."
    sudo dnf install -y nodejs npm

    # Install common global npm packages
    npm config set prefix ~/.npm-global
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    export PATH=~/.npm-global/bin:$PATH

    npm install -g \
        yarn \
        pnpm \
        typescript \
        ts-node \
        eslint \
        prettier \
        npm-check-updates
    success "Node.js and npm installed!"

    # Go
    info "Installing Go..."
    sudo dnf install -y golang

    # Setup Go environment
    mkdir -p ~/go/{bin,src,pkg}
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

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
        echo 'source "$HOME/.cargo/env"' >> ~/.bashrc

        # Install common Rust tools
        cargo install cargo-edit
        cargo install cargo-watch
        success "Rust installed!"
    else
        success "Rust already installed"
    fi

    # Additional development tools
    info "Installing additional development tools..."
    sudo dnf install -y \
        docker-ce-cli \
        podman-compose \
        lazygit \
        gh \
        gdb \
        valgrind \
        strace \
        ltrace
    success "Additional development tools installed!"
fi

# Install VS Code if requested
if [[ "${INSTALL_VSCODE}" == "true" ]]; then
    info "Installing VS Code from Microsoft COPR repository..."

    # Add Microsoft COPR repository
    if ! sudo dnf copr list --enabled | grep -q "microsoft/vscode"; then
        sudo dnf copr enable -y microsoft/vscode
    fi

    # Install VS Code
    sudo dnf install -y code

    success "VS Code installed!"

    info "Installing common VS Code extensions..."
    # Install common extensions
    code --install-extension ms-python.python
    code --install-extension golang.go
    code --install-extension rust-lang.rust-analyzer
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
    code --install-extension eamodio.gitlens
    code --install-extension ms-vscode.cmake-tools
    code --install-extension ms-vscode.cpptools
    success "VS Code extensions installed!"
fi

# Configure shell integrations
info "Configuring shell integrations..."

# Add fzf key bindings and completion
if [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
    echo 'source /usr/share/fzf/shell/key-bindings.bash' >> ~/.bashrc
fi

# Add zoxide init
echo 'eval "$(zoxide init bash)"' >> ~/.bashrc

# Add useful aliases
cat >> ~/.bashrc << 'EOF'

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

if [[ "${INSTALL_VSCODE}" == "true" ]]; then
    echo "  - VS Code: $(code --version 2>&1 | head -1)"
fi

echo ""
info "To start using your development environment:"
echo "  1. Exit this container (type 'exit' or Ctrl+D)"
echo "  2. Enter the container: distrobox enter ${CONTAINER_NAME}"
echo "  3. Start coding!"
echo ""
info "VS Code can be launched with: code"
info "Use 'z <directory>' instead of 'cd' for faster navigation with zoxide"
info "Use Ctrl+R for fzf history search"

INNER_SCRIPT

# Make the script executable
chmod +x "${SETUP_SCRIPT}"

# Run the setup script inside the container
info "Running setup inside the container..."
distrobox enter "${CONTAINER_NAME}" -- bash -c "
export INSTALL_VSCODE='${INSTALL_VSCODE}'
export INSTALL_MINIMAL='${INSTALL_MINIMAL}'
export CONTAINER_NAME='${CONTAINER_NAME}'
$(cat "${SETUP_SCRIPT}")
"

# Clean up temporary script
rm -f "${SETUP_SCRIPT}"

success "======================================"
success "Setup completed successfully!"
success "======================================"
echo ""
info "To enter your development container:"
echo "  distrobox enter ${CONTAINER_NAME}"
echo ""
info "To export apps from the container to your host:"
echo "  distrobox-export --app code  # Export VS Code"
echo ""
info "For more information, see docs/DEV_IN_CONTAINER.md"
