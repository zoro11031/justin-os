# Justin-OS User Scripts

These scripts are provided as optional tools for managing flatpaks and setting up development environments.

## Development Environment

### setup-fedora-distrobox.sh
Creates and configures a Fedora distrobox container for development with all essential tools and SDKs.

**What it installs:**
- Base dev tools: gcc, make, cmake, git, lazygit, gh (GitHub CLI)
- Language SDKs: Python, Node.js, Go, Rust (with common tools)
- VS Code: From Microsoft's official COPR repository
- Modern CLI: fzf, zoxide, ripgrep, fd, bat, eza, btop
- Shell integrations: useful aliases and completions

**Usage:**
```bash
# Default setup with all tools
bash setup-fedora-distrobox.sh

# Custom container name
bash setup-fedora-distrobox.sh --name my-dev-box

# Minimal installation (skip language SDKs)
bash setup-fedora-distrobox.sh --minimal

# Skip VS Code installation
bash setup-fedora-distrobox.sh --no-vscode

# Show all options
bash setup-fedora-distrobox.sh --help
```

**After setup:**
```bash
# Enter the container
distrobox enter dev-fedora

# Export VS Code to host menu
distrobox-export --app code
```

**Documentation:** See `docs/DEV_IN_CONTAINER.md` in the justin-os repository for detailed information.

---

## Flatpak Management

### install-common-flatpaks.sh
Installs all the common flatpak applications listed in the justin-os configuration.

**Usage:**
```bash
bash install-common-flatpaks.sh
```

### install-surface-flatpaks.sh
Installs Surface-specific flatpak applications (for justin-os-surface variant).

**Usage:**
```bash
bash install-surface-flatpaks.sh
```

### flatpak-auto-update.sh
Updates all installed flatpaks (both system and user).

**Usage:**
```bash
bash flatpak-auto-update.sh
```

---

## When to Use These

**Development setup:**
- To create a dedicated development container with all tools pre-configured
- To isolate development tools from the host system
- For a clean, reproducible development environment

**Flatpak scripts:**
- If the built-in flatpak installation during image build fails
- To manually install additional flatpaks from the justin-os list
- To manually trigger flatpak updates

## Note

Flatpak scripts are POSIX-compliant and can be run with either bash or sh.
