# ========================================
# ZSH Performance Benchmark Utilities
# ========================================

# Quick benchmark: measure shell startup time
alias zsh-bench='for i in {1..10}; do time zsh -i -c exit; done'

# Detailed benchmark: show what's taking time
alias zsh-profile='time zsh -i -c exit'

# Profile plugin loading (run before starting shell)
# Usage: zsh-debug-startup
zsh-debug-startup() {
  echo "Profiling zsh startup..."
  echo "Note: You may need to restart your shell to see output"
  PS4=$'%D{%M%S%.} %N:%i> '
  exec 3>&2 2>/tmp/zsh-startup.$$.log
  setopt xtrace prompt_subst
  source ~/.zshrc
  unsetopt xtrace
  exec 2>&3 3>&-
  echo "Profile written to /tmp/zsh-startup.$$.log"
  echo "View with: less /tmp/zsh-startup.$$.log"
}

# Show slowest loading parts
zsh-analyze() {
  if [[ -f /tmp/zsh-startup.$$.log ]]; then
    echo "Analyzing startup profile..."
    awk '{print $1}' /tmp/zsh-startup.$$.log | sort -n | tail -20
  else
    echo "No profile found. Run 'zsh-debug-startup' first."
  fi
}

# Clear completion cache (do this if completions seem slow)
alias zsh-clear-cache='rm -f ~/.zcompdump* && rm -rf $ZSH_CACHE_DIR/completions && echo "Cache cleared! Restart your shell."'

# Rehash completions (after installing new commands)
alias zsh-rehash='rehash && compinit'
