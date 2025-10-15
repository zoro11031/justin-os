# System Shell Configuration

## Overview

The system shell `/bin/sh` has been changed from `bash` to `dash` for improved performance and POSIX compliance. Interactive shells remain as `zsh`.

## Why Dash?

**Dash (Debian Almquist Shell)** is a POSIX-compliant shell that offers:

- **Performance**: 4x faster than bash for script execution
- **POSIX compliance**: Strictly adheres to POSIX standards
- **Lightweight**: Smaller memory footprint
- **Security**: Fewer features = smaller attack surface

### Use Cases:

- System scripts invoked with `#!/bin/sh`
- Boot scripts and system initialization
- Package manager scripts
- Any script requiring POSIX compatibility

## What Changed

### Before:

```bash
/bin/sh -> /usr/bin/bash
```

### After:

```bash
/bin/sh -> /usr/bin/dash
```

## Shell Usage

| Context                               | Shell | Path                        |
| ------------------------------------- | ----- | --------------------------- |
| System scripts (`#!/bin/sh`)          | dash  | `/bin/sh` → `/usr/bin/dash` |
| Interactive shell                     | zsh   | `/usr/bin/zsh`              |
| Bash-specific scripts (`#!/bin/bash`) | bash  | `/usr/bin/bash`             |

## Verification

Check which shell `/bin/sh` points to:

```bash
ls -l /bin/sh
# Output: /bin/sh -> /usr/bin/dash

# Or check the target directly
readlink /bin/sh
# Output: /usr/bin/dash
```

Test the shell:

```bash
/bin/sh --version
# Output: dash version info
```

## Important Notes

### Scripts That Use `/bin/sh`

Scripts that use `#!/bin/sh` (system scripts) will now run with dash. This is generally beneficial, but note:

✅ **Will work fine:**

- POSIX-compliant scripts
- Standard system utilities
- Most well-written shell scripts

⚠️ **May need adjustment:**

- Scripts using bash-specific features (arrays, `[[` conditionals, etc.)
- Scripts should use `#!/bin/bash` explicitly if they need bash features

### Interactive Shell Not Affected

Your interactive shell remains **zsh**. This change only affects:

- Scripts that explicitly use `#!/bin/sh`
- System scripts invoked by the OS
- Scripts that don't specify a shebang

### Compatibility

If you encounter a script that doesn't work with dash:

1. Change the shebang to `#!/bin/bash` (if you control the script)
2. Or run it explicitly with bash: `bash script.sh`

## Technical Details

### Implementation

1. **Package installation**: `dash` package added to `common-packages.yml`
2. **Symlink creation**: Script `set-dash-as-sh.sh` runs during build to replace `/bin/sh` symlink
3. **Verification**: Script verifies the symlink points to dash correctly

### Build Process

```yaml
# In recipe.yml:
- type: script
  scripts:
    - set-dash-as-sh.sh # Changes /bin/sh -> dash
```

### Files

- **Script**: `/files/scripts/set-dash-as-sh.sh`
- **Package**: Added to `common-packages.yml`
- **Module**: Added to `recipe.yml`

## Performance Comparison

Typical dash performance improvements over bash:

| Operation             | bash   | dash   | Speedup |
| --------------------- | ------ | ------ | ------- |
| Simple scripts        | 100ms  | 25ms   | 4x      |
| Boot scripts          | varies | varies | 2-4x    |
| System initialization | varies | varies | 2-3x    |

## References

- [Dash Homepage](http://gondor.apana.org.au/~herbert/dash/)
- [Debian Policy on /bin/sh](https://wiki.debian.org/DashAsBinSh)
- [Ubuntu Dash as /bin/sh](https://wiki.ubuntu.com/DashAsBinSh)
