# Development in a Fedora distrobox

This repository no longer installs full developer toolchains (editors, language runtimes, linters, etc.) system-wide. Instead, I recommend using a Fedora distrobox container to host all development tooling. This keeps the host image minimal and reproducible.

## Why distrobox?

- Isolated environment for your toolchains and language versions
- Easy to recreate and share
- Keeps host image small and secure
- Works well with GUI apps (via X11/Wayland) and CLI workflows

## Quick start (Fedora 42 dev container)

A convenience script is provided at `scripts/setup-fedora-distrobox.sh` which will:

- Create a distrobox container based on `registry.fedoraproject.org/fedora:42`
- Install common developer packages (Go, Python, Node.js, pip, npm, and optionally code-server)
- Provide notes on running GUI apps and VS Code remote workflows

Run the setup script:

```bash
bash scripts/setup-fedora-distrobox.sh
```

After creation, enter the distrobox:

```bash
distrobox enter dev-fedora-42
```

Inside the container install any project-specific tools and editors (or use the script's optional flags to install extra tooling).

## Recommendations

- For GUI editors: either run them inside the distrobox (if you forward Wayland/X11 and allow GUI) or use VS Code's Remote - Containers or code-server inside the container and connect from the host browser or VS Code remote.
- Keep version managers (asdf, pyenv, nvm) inside the container to avoid host contamination.
- Persist your container's data or bind-mount project directories so code and caches are available on the host.

## Example: VS Code + Remote

If you need VS Code's full GUI, prefer one of:

- Use VS Code on the host and connect via Remote - SSH / Remote - Containers to the distrobox
- Install `code-server` inside the distrobox and connect via browser

See `scripts/setup-fedora-distrobox.sh --help` for available options.
