if [[ ! -d ~/.zplug ]];then
    git clone https://github.com/zplug/zplug ~/.zplug
fi
source ~/.zplug/init.zsh

# Source spaceship config BEFORE loading spaceship theme
# This ensures all SPACESHIP_* variables are set before initialization
if [[ -f "$SPACESHIP_CONFIG" ]]; then
  source "$SPACESHIP_CONFIG"
fi

# Core plugins
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"

# Required for spaceship async mode
zplug "mafredri/zsh-async", from:github

# FZF git integration (CTRL-G bindings for git operations)
zplug "junegunn/fzf-git.sh", from:github

zplug "spaceship-prompt/spaceship-prompt", use:spaceship.zsh, from:github, as:theme

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load

# Lazy load direnv - initialize on first directory change or command use
_direnv_lazy_load() {
  # Remove this function and the chpwd hook to avoid re-triggering
  autoload -Uz add-zsh-hook
  add-zsh-hook -d chpwd _direnv_lazy_load
  unfunction direnv _direnv_lazy_load

  # Now actually load direnv
  eval "$(direnv hook zsh)"

  # If we're in a directory with .envrc, load it now
  if [[ -f .envrc ]]; then
    direnv allow
  fi
}

# Hook into directory changes
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _direnv_lazy_load

# Also wrap the direnv command itself
direnv() {
  _direnv_lazy_load
  direnv "$@"
}
