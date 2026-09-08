# Add custom completion directory
fpath=(~/.zfunc $fpath)

# ponytail: compinit is called once, at the end of ~/.zshrc, AFTER plugins.zsh
# loads zsh-completions. Calling it here too just made compinit/compdump run
# 3x on every startup (~1.6s). Just prep the autoload here.
autoload -Uz compinit

# history setup
setopt SHARE_HISTORY
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000
HISTSIZE=999
setopt HIST_EXPIRE_DUPS_FIRST

# autocompletion using arrow keys (based on history)
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward
