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
