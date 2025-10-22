# Security Guidelines

## Sensitive Configuration Files

This repository contains configuration templates for WinApps that require credentials. **NEVER commit files with real passwords or credentials.**

### Required Setup

Before using WinApps, you need to create configuration files from the templates:

```bash
# Copy and edit with your actual credentials
cp files/home/.config/winapps/winapps.conf.template files/home/.config/winapps/winapps.conf
cp files/home/.config/winapps/compose.yaml.template files/home/.config/winapps/compose.yaml

# Edit these files and replace placeholders:
# - "YourUsername" with your actual Windows username
# - "YourPasswordHere" with your actual Windows password
```

### Protected Files

The following files are **intentionally excluded** from git tracking via `.gitignore`:

- `files/home/.config/winapps/winapps.conf` - Contains RDP credentials
- `files/home/.config/winapps/compose.yaml` - Contains Windows VM password
- All `.bak`, `.backup`, `.old` files - May contain sensitive data
- All `.env*` files (except `.env.template` and `.env.example`)
- All private keys (`.key`, `.pem`, etc.)
- SSH keys, API tokens, and cloud credentials

### Important Notes

1. **Never commit real credentials** - Always use the `.template` files in the repository
2. **Review before committing** - Run `git status` and check for sensitive files before committing
3. **Rotate compromised credentials** - If credentials are accidentally committed, change them immediately
4. **Clean git history** - If sensitive data was committed, see the section below

## Cleaning Sensitive Data from Git History

If sensitive data was committed to git history, you need to remove it using one of these methods:

### Method 1: Using git filter-repo (Recommended)

```bash
# Install git-filter-repo if not already installed
pip3 install git-filter-repo

# Remove specific files from all history
git filter-repo --path files/home/.config/winapps/winapps.conf --invert-paths
git filter-repo --path files/home/.config/winapps/compose.yaml --invert-paths
git filter-repo --path files/home/.config/winapps/compose.yaml.bak --invert-paths
git filter-repo --path files/home/.config/winapps/compose.yaml.bak.bak --invert-paths

# Force push to remote (WARNING: This rewrites history!)
git push origin --force --all
```

### Method 2: Using BFG Repo-Cleaner

```bash
# Download BFG
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# Remove files from history
java -jar bfg-1.14.0.jar --delete-files winapps.conf
java -jar bfg-1.14.0.jar --delete-files compose.yaml

# Clean up and force push
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push origin --force --all
```

### Important Warnings

- **Rewriting history affects all collaborators** - Coordinate with your team before force-pushing
- **Change compromised passwords immediately** - Old passwords in history are still exposed until removed
- **Consider the password compromised** - Even after cleaning, someone may have already cloned the repo with the credentials

## Best Practices

1. Use environment variables for sensitive configuration when possible
2. Use secret management tools (e.g., pass, 1Password, Bitwarden) for storing credentials
3. Enable pre-commit hooks to scan for secrets before committing
4. Regular security audits of the repository
5. Use GitHub's secret scanning if available

## Security Issues

If you discover a security issue, please:
1. **DO NOT** open a public issue
2. Change any compromised credentials immediately
3. Contact the repository maintainer privately
