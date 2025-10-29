# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) for easy synchronization across multiple machines.

## Overview

This repository contains configuration files (dotfiles) for various tools and applications. Using GNU Stow, these dotfiles can be easily installed and managed through symbolic links.

## Prerequisites

- Git
- [GNU Stow](https://www.gnu.org/software/stow/)

### Installing GNU Stow

**Ubuntu/Debian:**
```bash
sudo apt-get install stow
```

**macOS:**
```bash
brew install stow
```

**Arch Linux:**
```bash
sudo pacman -S stow
```

## Repository Structure

Each directory represents a "package" that can be independently installed:

```
dotfiles/
├── bash/          # Bash configuration (.bashrc, .bash_profile)
├── git/           # Git configuration (.gitconfig)
├── vim/           # Vim configuration (.vimrc)
├── zsh/           # Zsh configuration (.zshrc)
├── tmux/          # Tmux configuration (.tmux.conf)
└── install.sh     # Installation script
```

Each package contains files organized as they would appear in your home directory. For example:
- `bash/.bashrc` will be linked to `~/.bashrc`
- `git/.gitconfig` will be linked to `~/.gitconfig`

## Installation

### Clone the Repository

First, clone this repository to your home directory or any preferred location. By default the
configuration files expect to live in `~/.dotfiles`, but you can override that by exporting a
`DOTFILES` environment variable that points to the repository.

```bash
git clone https://github.com/zoro11031/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

If you would rather keep the repository elsewhere, set the environment variable accordingly before
running the scripts. For example:

```bash
export DOTFILES="$HOME/my-dotfiles"
cd "$DOTFILES"
```

### Install All Packages

To install all dotfiles at once:

```bash
./install.sh
```

### Install Specific Packages

To install only specific packages:

```bash
./install.sh bash git vim
```

### Manual Installation (without script)

You can also manually install packages using stow:

```bash
cd "$DOTFILES"
stow bash     # Install bash configuration
stow git      # Install git configuration
stow vim      # Install vim configuration
```

## Uninstalling

To uninstall packages, use the uninstall flag:

```bash
./install.sh --uninstall bash git
```

Or manually with stow:

```bash
cd "$DOTFILES"
stow -D bash  # Remove bash configuration
```

## Updating

To update your dotfiles:

1. Pull the latest changes:
   ```bash
   cd "$DOTFILES"
   git pull
   ```

2. Reinstall the packages:
   ```bash
   ./install.sh --reinstall
   ```

## Customization

### Local Overrides

To add machine-specific customizations without modifying the repository:

- For bash: Create `~/.bashrc.local`
- For zsh: Create `~/.zshrc.local`

These files will be automatically sourced if they exist and are ignored by git.

### Modifying Dotfiles

1. Edit the files in the dotfiles repository
2. Commit your changes:
   ```bash
   git add .
   git commit -m "Update configuration"
   git push
   ```

## Available Configurations

### Bash
- Command history settings
- Colorized prompt
- Common aliases (ll, la, grep)
- Bash completion support

### Git
- User configuration (name, email)
- Color output
- Useful aliases (st, co, br, ci, lg)
- Default branch settings

### Vim
- Syntax highlighting
- Line numbers
- Smart indentation
- Search settings
- No backup files

### Zsh
- Command history
- Colorized prompt
- Completion system
- Common aliases

### Tmux
- Custom prefix (Ctrl-a)
- Mouse support
- Better pane splitting
- Status bar customization

## Syncing Across Machines

To sync dotfiles across multiple machines:

1. **First machine (initial setup):**
   ```bash
   cd "$DOTFILES"
   # Make your changes
   git add .
   git commit -m "Your changes"
   git push
   ```

2. **Other machines (sync):**
   ```bash
   cd "$DOTFILES"
   git pull
   ./install.sh --reinstall
   ```

## Troubleshooting

### Conflicts with Existing Files

If you have existing dotfiles, stow will warn you about conflicts. You can:

1. Backup your existing files:
   ```bash
   mv ~/.bashrc ~/.bashrc.backup
   ```

2. Then run the installation again

### Checking What Will Be Linked

To see what stow will do without actually doing it:

```bash
stow -n -v bash  # Dry run with verbose output
```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to fork this repository and customize it for your own use. If you have suggestions for improvements, please open an issue or pull request.
