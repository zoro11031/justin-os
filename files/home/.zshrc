# ========================================
# ULTRA-OPTIMIZED ZSHRC
# Minimal OMZ loading - only what we actually use
# ========================================

# ========================================
# Core Performance Settings
# ========================================
# Path configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# OMZ path (system-wide or user installation)
if [ -d "/usr/share/oh-my-zsh" ]; then
  export ZSH="/usr/share/oh-my-zsh"
else
  export ZSH="$HOME/.oh-my-zsh"
fi
export ZSH_CACHE_DIR="$ZSH/cache"

# Fast compinit - only check once per day
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qNmh+24) ]]; then
  compinit
else
  compinit -C
fi

# ========================================
# History Configuration (Fish-like)
# ========================================
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS        # Don't display duplicates when searching
setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS        # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks before recording entry
setopt HIST_VERIFY              # Don't execute immediately upon history expansion
setopt INC_APPEND_HISTORY       # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY            # Share history between all sessions

# ========================================
# Completion Settings (Fish-like)
# ========================================
# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Speed up completion
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/completions"
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' squeeze-slashes true

# Better completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ========================================
# Directory Navigation
# ========================================
setopt AUTO_CD              # If a command is not found but is a directory, cd into it
setopt AUTO_PUSHD           # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS    # Don't push multiple copies of the same directory
setopt PUSHD_SILENT         # Don't print the directory stack after pushd or popd

# ========================================
# Correction
# ========================================
setopt CORRECT              # Command correction
CORRECT_IGNORE='_*'
CORRECT_IGNORE_FILE='.*'

# ========================================
# Load Essential OMZ Libraries (Minimal)
# ========================================
# Only load the libraries we actually need
source "$ZSH/lib/git.zsh"           # Git functions for prompt/aliases
source "$ZSH/lib/key-bindings.zsh"  # Essential key bindings
source "$ZSH/lib/completion.zsh"    # Completion enhancements

# ========================================
# Load Core Plugins Directly
# ========================================
# Git plugin
[[ -f "$ZSH/plugins/git/git.plugin.zsh" ]] && source "$ZSH/plugins/git/git.plugin.zsh"

# Z - directory jumping
[[ -f "$ZSH/plugins/z/z.plugin.zsh" ]] && source "$ZSH/plugins/z/z.plugin.zsh"

# Sudo plugin
[[ -f "$ZSH/plugins/sudo/sudo.plugin.zsh" ]] && source "$ZSH/plugins/sudo/sudo.plugin.zsh"

# Zsh-completions (if installed)
if [[ -d "$ZSH/custom/plugins/zsh-completions" ]]; then
  fpath=("$ZSH/custom/plugins/zsh-completions/src" $fpath)
fi

# History substring search
if [[ -f "$ZSH/plugins/history-substring-search/history-substring-search.zsh" ]]; then
  source "$ZSH/plugins/history-substring-search/history-substring-search.zsh"
  # Bind keys
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# Zsh-autopair
[[ -f "$ZSH/custom/plugins/zsh-autopair/zsh-autopair.plugin.zsh" ]] && \
  source "$ZSH/custom/plugins/zsh-autopair/zsh-autopair.plugin.zsh"

# Zsh-autosuggestions (async for performance)
if [[ -f "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=true
  ZSH_AUTOSUGGEST_MANUAL_REBIND=1
  source "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Fast-syntax-highlighting (load LAST for best performance)
[[ -f "$ZSH/custom/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
  source "$ZSH/custom/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ========================================
# FZF Integration
# ========================================
export FZF_BASE=/usr/share/fzf
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# ========================================
# Lazy-loaded plugins for better performance
# ========================================

# Lazy load colored-man-pages (only when viewing man pages)
unalias man 2>/dev/null
function man() {
  # Load colored-man-pages plugin on first use
  if ! typeset -f _colorman > /dev/null; then
    if [[ -f $ZSH/plugins/colored-man-pages/colored-man-pages.plugin.zsh ]]; then
      source $ZSH/plugins/colored-man-pages/colored-man-pages.plugin.zsh
    fi
  fi
  # Call the actual man command
  command man "$@"
}

# Lazy load command-not-found (only when command fails)
if [[ -f /etc/zsh_command_not_found ]]; then
  command_not_found_handler() {
    if [[ -x /usr/lib/command-not-found ]]; then
      /usr/lib/command-not-found -- "$1"
      return $?
    elif [[ -x /usr/share/command-not-found/command-not-found ]]; then
      /usr/share/command-not-found/command-not-found -- "$1"
      return $?
    else
      printf "zsh: command not found: %s\n" "$1" >&2
      return 127
    fi
  }
fi

# Lazy load alias-finder (only when explicitly called)
alias-finder() {
  if [[ ! -f $ZSH/plugins/alias-finder/alias-finder.plugin.zsh ]]; then
    echo "alias-finder plugin not found"
    return 1
  fi
  # Load the plugin on first use
  if ! typeset -f _alias-finder > /dev/null; then
    source $ZSH/plugins/alias-finder/alias-finder.plugin.zsh
  fi
  # Call the actual function
  _alias-finder "$@"
}

# Lazy load zsh-interactive-cd (only when cd is used with no args in certain contexts)
if [[ -f $ZSH/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh ]]; then
  _lazy_load_interactive_cd() {
    unfunction _lazy_load_interactive_cd
    source $ZSH/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh
  }
  # Bind to Ctrl+X Ctrl+F for interactive cd (loads plugin on first use)
  bindkey -s '^X^F' '^Q_lazy_load_interactive_cd\n'
fi

# ========================================
# Starship Prompt (Fast alternative to OMZ themes)
# ========================================
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
else
  # Fallback to robbyrussell theme if starship not found
  if [[ -f $ZSH/themes/robbyrussell.zsh-theme ]]; then
    source $ZSH/themes/robbyrussell.zsh-theme
  else
    # Ultimate fallback: simple prompt with cwd
    PROMPT='%F{cyan}%~%f %F{green}❯%f '
  fi
fi

# ========================================
# Load Custom Configuration Files
# ========================================
# Load custom configs from $ZSH/custom/*.zsh (excluding example.zsh)
for config_file ($ZSH/custom/*.zsh~$ZSH/custom/example.zsh(N)); do
  source $config_file
done
unset config_file

# ========================================
# Additional Environment Variables
# ========================================
export WINAPPS_SRC_DIR="$HOME/.local/bin/winapps-src"
