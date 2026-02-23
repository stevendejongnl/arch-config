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

# Initialize direnv properly
eval "$(direnv hook zsh)"
