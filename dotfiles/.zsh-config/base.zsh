export TMPDIR=~/tmp/
export EDITOR=nvim
export VISUAL=nvim
export SPACESHIP_CONFIG="$HOME/.zsh-config/spaceship.zsh"

source $HOME/.aliases

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

# Home/End/Delete — bind via terminfo so it's TERM-agnostic
bindkey "${terminfo[khome]}" beginning-of-line   # \e[1~
bindkey "${terminfo[kend]}"  end-of-line          # \e[4~
bindkey "${terminfo[kdch1]}" delete-char          # \e[3~
