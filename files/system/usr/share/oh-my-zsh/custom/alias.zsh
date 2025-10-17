# ========================================
# ALIASES & HELPER FUNCTIONS
# Core utility functions (mkcd, ff, extract) are in .zshrc
# ========================================

# ========================================
# Basic Aliases
# ========================================
alias vim='nvim'
alias please='sudo $(fc -ln -1)'
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

# Grep with color
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS}'

# History shortcuts
alias h='history'
alias hgrep="fc -El 0 | grep"

# Disk usage
alias dud='du -d 1 -h'
(( $+commands[duf] )) || alias duf='du -sh *'

# ========================================
# Global Aliases (for piping)
# ========================================
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"

# ========================================
# Directory Navigation
# ========================================
alias ...='../..'
alias ....='../../..'
alias .....='../../../..'
alias d='dirs -v | head -10'

# ========================================
# Helper Functions
# ========================================

# Search aliases by keyword
aliases() {
  if [[ -z "$1" ]]; then
    echo "Usage: aliases <keyword>"
    echo "Example: aliases git"
    echo ""
    echo "Or use 'help-aliases' to see common/useful aliases"
    return 1
  fi
  
  echo "Aliases matching '$1':"
  if command -v bat &> /dev/null; then
    alias | grep -i "$1" | command bat --language=bash --paging=never
  else
    alias | grep -i "$1"
  fi
}

# Show help for common aliases and commands
help-aliases() {
  local content='# Common Aliases & Commands

## Git Shortcuts (from oh-my-zsh git plugin)
gst     = git status
ga      = git add
gaa     = git add --all
gc      = git commit -v
gcmsg   = git commit -m
gp      = git push
gl      = git pull
gco     = git checkout
gcb     = git checkout -b (create new branch)
gd      = git diff
glog    = git log --oneline --decorate --graph
gcl     = git clone
gb      = git branch
gba     = git branch -a

## File Operations
cat     = bat with syntax highlighting (if installed)
less    = bat with paging (if installed)
vim     = nvim (neovim)
ff      = Find files by name (case-insensitive)

## Directory Navigation
z <name> = Jump to frequently used directory
d        = Show directory stack
..       = cd ..
...      = cd ../..
....     = cd ../../..

## System Commands
please   = Run last command with sudo
mkcd     = Create directory and cd into it
extract  = Extract any archive (tar, zip, 7z, etc.)
ff       = Find files by name pattern

## Search Functions
aliases <keyword>  = Show aliases matching keyword
help-aliases       = Show this help menu
h                  = Show command history
hgrep <term>       = Search command history

## Global Aliases (use at end of command)
H   = | head
T   = | tail
G   = | grep
L   = | less
NE  = 2> /dev/null
NUL = > /dev/null 2>&1

Example: cat file.txt G "error" H

## Keyboard Shortcuts
ESC ESC   = Add sudo to current command
Ctrl+R    = Fuzzy search command history (with fzf)
Ctrl+T    = Fuzzy file finder (with fzf)
Alt+C     = Fuzzy directory finder (with fzf)
↑/↓       = History substring search

## Tips
- Use "which <alias>" to see what an alias does
- Use "man <command>" for detailed help
- Type partial command + UP arrow for history search
- Use "z" to jump to frequently used directories'

  if command -v bat &> /dev/null; then
    echo "$content" | command bat --language=markdown --paging=never
  else
    echo "$content"
  fi
}
