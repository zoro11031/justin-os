alias vim='nvim'
alias please='sudo $(fc -ln -1)'

# ========================================
# Useful aliases from common-aliases (cherry-picked for performance)
# ========================================

# Quick edit .zshrc
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

# Enhanced grep with color
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS}'

# History shortcuts
alias h='history'
alias hgrep="fc -El 0 | grep"

# Disk usage shortcuts
alias dud='du -d 1 -h'
(( $+commands[duf] )) || alias duf='du -sh *'

# Find shortcuts
(( $+commands[fd] )) || alias fd='find . -type d -name'
alias ff='find . -type f -name'

# Global aliases for piping (super useful!)
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"

# Safe mode for destructive commands (optional - comment out if annoying)
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

# ========================================
# Utility Functions
# ========================================

# Help command to show useful aliases (optionally filter by keyword)
help-aliases() {
  # If argument provided, search for matching aliases
  if [ -n "$1" ]; then
    echo "Aliases matching '$1':"
    if command -v bat &> /dev/null; then
      alias | grep -i "$1" | bat --language=bash --style=plain --paging=never
    else
      alias | grep -i "$1"
    fi
    return
  fi
  
  # Otherwise show the full help menu
  if command -v bat &> /dev/null; then
    cat << 'EOF' | bat --language=markdown --style=plain --paging=never
# Common Aliases & Commands

## Git Shortcuts (from oh-my-zsh git plugin)
gst     = git status
ga      = git add
gc      = git commit -v
gp      = git push
gl      = git pull
gco     = git checkout
gcb     = git checkout -b (create new branch)
gd      = git diff
glog    = git log --oneline --decorate --graph
gcl     = git clone

## File Operations
cat     = bat --paging=never (syntax highlighting)
less    = bat --paging=always (syntax highlighting)
vim     = nvim (neovim)
ff      = Find files by name

## Directory Navigation
z <name> = Jump to frequently used directory
..       = cd ..
...      = cd ../..
....     = cd ../../..

## System
please  = sudo <last command>

## Global Pipe Aliases
H       = | head
T       = | tail
G       = | grep
L       = | less

## Keyboard Shortcuts
ESC ESC = Add 'sudo' to current command
Ctrl+R  = Search command history
Ctrl+T  = Fuzzy file search (fzf)
Alt+C   = Fuzzy directory search (fzf)

## Tips
- Use 'man <command>' to see detailed help
- Use 'which <alias>' to see what an alias does
- Type partial command + UP arrow for history search
EOF
  else
    cat << 'EOF'
# Common Aliases & Commands

## Git Shortcuts (from oh-my-zsh git plugin)
gst     = git status
ga      = git add
gc      = git commit -v
gp      = git push
gl      = git pull
gco     = git checkout
gcb     = git checkout -b (create new branch)
gd      = git diff
glog    = git log --oneline --decorate --graph
gcl     = git clone

## File Operations
cat     = bat --paging=never (syntax highlighting)
less    = bat --paging=always (syntax highlighting)
vim     = nvim (neovim)
ff      = Find files by name

## Directory Navigation
z <name> = Jump to frequently used directory
..       = cd ..
...      = cd ../..
....     = cd ../../..

## System
please  = sudo <last command>

## Global Pipe Aliases
H       = | head
T       = | tail
G       = | grep
L       = | less

## Keyboard Shortcuts
ESC ESC = Add 'sudo' to current command
Ctrl+R  = Search command history
Ctrl+T  = Fuzzy file search (fzf)
Alt+C   = Fuzzy directory search (fzf)

## Tips
- Use 'man <command>' to see detailed help
- Use 'which <alias>' to see what an alias does
- Type partial command + UP arrow for history search
EOF
  fi
}

