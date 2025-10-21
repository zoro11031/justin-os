# Justin-OS Flatpak Scripts

These scripts are provided as optional tools for managing flatpaks if needed.

## Available Scripts

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

## When to Use These

- If the built-in flatpak installation during image build fails
- To manually install additional flatpaks from the justin-os list
- To manually trigger flatpak updates

## Note

These scripts are POSIX-compliant and can be run with either bash or sh.
