#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
[ -f /home/stevendejong/.config/cani/completions/_cani.bash ] && source /home/stevendejong/.config/cani/completions/_cani.bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/stevendejong/.lmstudio/bin"
# End of LM Studio CLI section

# safe-chain (npm/npx/pip/... malware guard); binary lives in ~/.npm-global/bin
export PATH="$HOME/.npm-global/bin:$PATH"
[ -f "$HOME/.safe-chain/scripts/init-posix.sh" ] && source "$HOME/.safe-chain/scripts/init-posix.sh" # Safe-chain

# Added by JetBrains Context CLI installer
case ":$PATH:" in
    *":/home/stevendejong/.jbcontext/bin:"*) ;;
    *) export PATH="$PATH:/home/stevendejong/.jbcontext/bin" ;;
esac
