# ========================================
# OPTIMIZED ZSHRC
# Fast startup with all essential features
# ========================================

# ========================================
# Path & Environment
# ========================================
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# OMZ path detection
if [ -d "/usr/share/oh-my-zsh" ]; then
  export ZSH="/usr/share/oh-my-zsh"
else
  export ZSH="$HOME/.oh-my-zsh"
fi
export ZSH_CACHE_DIR="$ZSH/cache"

# Additional environment
export WINAPPS_SRC_DIR="$HOME/.local/bin/winapps-src"
export LESS='-R -X -F'
export LESSHISTFILE='-'
export MANPAGER='less -R'
export GROFF_NO_SGR=1
export CLICOLOR=1
export GREP_COLOR='1;32'
export KEYTIMEOUT=1

# Bat integration (if available) - but NOT for man pages
if command -v bat &> /dev/null; then
  export BAT_THEME="ansi"
  alias cat='bat --paging=never'
  alias less='bat --paging=always'
fi

# ========================================
# Completion System (Fast)
# ========================================
autoload -Uz compinit
# Only rebuild completion cache once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qNmh+24) ]]; then
  compinit
else
  compinit -C
fi

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/completions"
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# ========================================
# History Configuration
# ========================================
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ========================================
# Shell Options
# ========================================
# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt PUSHD_MINUS

# Correction & globbing
setopt CORRECT
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NO_NOMATCH

CORRECT_IGNORE='_*'
CORRECT_IGNORE_FILE='.*'

# Directory aliases for quick navigation
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias d='dirs -v | head -10'

# ========================================
# Load OMZ Libraries (Essential only)
# ========================================
source "$ZSH/lib/git.zsh" 2>/dev/null
source "$ZSH/lib/key-bindings.zsh" 2>/dev/null
source "$ZSH/lib/completion.zsh" 2>/dev/null

# ========================================
# Load Plugins
# ========================================
# Core plugins
[[ -f "$ZSH/plugins/git/git.plugin.zsh" ]] && source "$ZSH/plugins/git/git.plugin.zsh"
[[ -f "$ZSH/plugins/z/z.plugin.zsh" ]] && source "$ZSH/plugins/z/z.plugin.zsh"
[[ -f "$ZSH/plugins/sudo/sudo.plugin.zsh" ]] && source "$ZSH/plugins/sudo/sudo.plugin.zsh"

# Completions
[[ -d "$ZSH/custom/plugins/zsh-completions" ]] && \
  fpath=("$ZSH/custom/plugins/zsh-completions/src" $fpath)

# History substring search
if [[ -f "$ZSH/plugins/history-substring-search/history-substring-search.zsh" ]]; then
  source "$ZSH/plugins/history-substring-search/history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# Autopair
[[ -f "$ZSH/custom/plugins/zsh-autopair/zsh-autopair.plugin.zsh" ]] && \
  source "$ZSH/custom/plugins/zsh-autopair/zsh-autopair.plugin.zsh"

# Autosuggestions (async)
if [[ -f "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=true
  ZSH_AUTOSUGGEST_MANUAL_REBIND=1
  source "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax highlighting (load last)
[[ -f "$ZSH/custom/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
  source "$ZSH/custom/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ========================================
# FZF Integration
# ========================================
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  export FZF_BASE=/usr/share/fzf
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# ========================================
# Command-not-found handler
# ========================================
if [[ -f /etc/zsh_command_not_found ]]; then
  command_not_found_handler() {
    if [[ -x /usr/lib/command-not-found ]]; then
      /usr/lib/command-not-found -- "$1"
    elif [[ -x /usr/share/command-not-found/command-not-found ]]; then
      /usr/share/command-not-found/command-not-found -- "$1"
    else
      printf "zsh: command not found: %s\n" "$1" >&2
    fi
    return 127
  }
fi

# ========================================
# Prompt (Starship or fallback)
# ========================================
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
elif [[ -f $ZSH/themes/robbyrussell.zsh-theme ]]; then
  source $ZSH/themes/robbyrussell.zsh-theme
else
  PROMPT='%F{cyan}%~%f %F{green}❯%f '
fi

# ========================================
# Core Utility Functions
# ========================================

# Create directory and cd into it
unalias mkcd 2>/dev/null
mkcd() {
  [[ -z "$1" ]] && { echo "Usage: mkcd <directory>"; return 1; }
  mkdir -p "$1" && cd "$1"
}

# Find files by name (case-insensitive)
unalias ff 2>/dev/null
ff() {
  if [[ -z "$1" ]]; then
    echo "Usage: ff <pattern>"
    echo "Example: ff .zshrc"
    echo "         ff '*.py'"
    return 1
  fi
  find . -iname "*$1*" 2>/dev/null
}

# Extract any archive format
unalias extract 2>/dev/null
extract() {
  if [[ ! -f "$1" ]]; then
    echo "Error: '$1' is not a valid file"
    return 1
  fi
  
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.zip)            unzip "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x "$1" ;;
    *.Z)              uncompress "$1" ;;
    *)                echo "Error: '$1' cannot be extracted via extract()"; return 1 ;;
  esac
}

# ========================================
# Load Custom Configs
# ========================================
for config_file in $ZSH/custom/*.zsh(N); do
  [[ $(basename "$config_file") != "example.zsh" ]] && source "$config_file"
done
unset config_file
