# Development in a Fedora distrobox

This repository no longer installs full developer toolchains (editors, language runtimes, linters, etc.) system-wide. Instead, I recommend using a Fedora distrobox container to host all development tooling. This keeps the host image minimal and reproducible.

## Why distrobox?

- Isolated environment for your toolchains and language versions
- Easy to recreate and share
- Keeps host image small and secure
- Works well with GUI apps (via X11/Wayland) and CLI workflows
- Uses the official Universal Blue Fedora toolbox image for maximum compatibility

## Quick start

A comprehensive setup script is provided in `~/Documents/justin-os-scripts/setup-fedora-distrobox.sh` which will:

- Create a distrobox container using `ghcr.io/ublue-os/fedora-toolbox:latest`
- Install common development tools and build essentials
- Install language SDKs: Python, Node.js, Go, and Rust with their toolchains
- Install VS Code from Microsoft's COPR repository
- Install modern CLI utilities: fzf, zoxide, ripgrep, fd, bat, eza, and more
- Configure shell integrations and useful aliases
- Install development utilities: lazygit, gh (GitHub CLI), docker/podman-compose

Run the setup script:

```bash
cd ~/Documents/justin-os-scripts
bash setup-fedora-distrobox.sh
```

After creation, enter the distrobox:

```bash
distrobox enter dev-fedora
```

## Script options

The setup script supports several customization options:

```bash
cd ~/Documents/justin-os-scripts

# Show all available options
bash setup-fedora-distrobox.sh --help

# Create with custom name
bash setup-fedora-distrobox.sh --name my-dev-env

# Use a different toolbox image
bash setup-fedora-distrobox.sh --image ghcr.io/ublue-os/fedora-toolbox:40

# Skip VS Code installation
bash setup-fedora-distrobox.sh --no-vscode

# Minimal installation (only essential tools, skip language SDKs)
bash setup-fedora-distrobox.sh --minimal
```

## What's installed

### Base Development Tools
- Build essentials: gcc, g++, make, cmake, automake, autoconf
- Version control: git, git-lfs, gh (GitHub CLI), lazygit
- Essential utilities: curl, wget, tar, unzip, patch, jq
- Editors: vim, nano

### Modern CLI Tools
- **fzf**: Fuzzy finder (Ctrl+R for history search)
- **zoxide**: Smarter cd command (use `z` instead of `cd`)
- **ripgrep**: Fast grep alternative
- **fd**: Fast find alternative
- **bat**: Cat with syntax highlighting
- **eza**: Modern ls replacement
- **btop**: Better system monitor
- **ncdu**: Disk usage analyzer

### Language SDKs (unless --minimal)
- **Python**: Python 3, pip, pipx, virtualenv
  - Tools: poetry, black, ruff, mypy, pylint
- **Node.js**: Latest Node.js, npm, yarn, pnpm
  - Tools: typescript, eslint, prettier, ts-node
- **Go**: Latest Go with common tools
  - Tools: gopls, golangci-lint, staticcheck
- **Rust**: Rustup, cargo, rustc
  - Tools: cargo-edit, cargo-watch

### VS Code (unless --no-vscode)
- Installed from Microsoft's official COPR repository
- Common extensions pre-installed:
  - Python, Go, Rust language support
  - ESLint, Prettier, GitLens
  - C/C++ tools, CMake tools

### Container Tools
- docker-ce-cli
- podman-compose
- Development debuggers: gdb, valgrind, strace, ltrace

## Using VS Code

VS Code is installed inside the container by default. You have several options:

### Option 1: Run VS Code from the container (recommended)
```bash
distrobox enter dev-fedora
code /path/to/your/project
```

### Option 2: Export VS Code to the host
```bash
distrobox enter dev-fedora
distrobox-export --app code
```
After exporting, VS Code will appear in your application menu and will run inside the container automatically.

### Option 3: Use VS Code Remote Development
If you prefer VS Code installed on your host:
1. Install the "Remote - Containers" extension
2. Connect to the distrobox container
3. All tools and SDKs from the container will be available

## Shell integrations

The setup script configures useful shell integrations:

- **fzf**: Ctrl+R for fuzzy history search
- **zoxide**: Use `z <directory>` for smart directory jumping
- **Aliases**: Common shortcuts for git, docker, development tools

### Useful aliases
```bash
g='git'              # Git shortcut
lg='lazygit'         # Lazygit TUI
dc='docker-compose'  # Docker compose
v='nvim'             # Neovim
ls='eza'             # Better ls
cat='bat'            # Cat with syntax
cd='z'               # Zoxide smart cd
```

## Recommendations

- **Project directories**: By default, your home directory is shared with the container
- **Version managers**: Install asdf, pyenv, nvm inside the container to avoid host contamination
- **Container persistence**: Distrobox containers persist across reboots
- **GUI apps**: X11/Wayland forwarding is automatic - GUI apps just work
- **Exportable apps**: Use `distrobox-export` to add container apps to your host menu

## Advanced usage

### Recreate container with new setup
```bash
cd ~/Documents/justin-os-scripts
bash setup-fedora-distrobox.sh --name dev-fedora
# Script will prompt to remove existing container and recreate
```

### Multiple containers for different projects
```bash
cd ~/Documents/justin-os-scripts

# Web development container
bash setup-fedora-distrobox.sh --name web-dev

# Systems programming (minimal, no Node.js)
bash setup-fedora-distrobox.sh --name systems-dev --minimal

# Python-only container
bash setup-fedora-distrobox.sh --name python-dev --minimal --no-vscode
```

### Accessing host files
Your home directory is automatically mounted. For other directories:
```bash
distrobox create --name dev-fedora \
  --image ghcr.io/ublue-os/fedora-toolbox:latest \
  --volume /path/on/host:/path/in/container
```

## Troubleshooting

### Container won't start
```bash
# Check container status
distrobox list

# Remove and recreate
distrobox rm -f dev-fedora
cd ~/Documents/justin-os-scripts
bash setup-fedora-distrobox.sh
```

### VS Code won't launch
```bash
# Make sure you're inside the container
distrobox enter dev-fedora
code --version

# If not installed, install manually
sudo dnf copr enable -y microsoft/vscode
sudo dnf install -y code
```

### Update tools inside container
```bash
distrobox enter dev-fedora

# Update system packages
sudo dnf update -y

# Update language tools
pip install --upgrade pipx poetry black ruff
npm update -g
rustup update
go install golang.org/x/tools/gopls@latest
```

## See also

- [Distrobox documentation](https://distrobox.it/)
- [Universal Blue Fedora Toolbox images](https://github.com/ublue-os/fedora-toolbox)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
