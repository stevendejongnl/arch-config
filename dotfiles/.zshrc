export ANDROID_HOME=/home/stevendejong/Android/Sdk
export PATH=$HOME/bin:$HOME/.local/bin:$HOME/.local/share/JetBrains/Toolbox/scripts:/usr/local/bin:$HOME/.lmstudio/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH

source $HOME/.zsh-config/autocompletion.zsh
source $HOME/.zsh-config/base.zsh
source $HOME/.zsh-config/sudo.zsh
source $HOME/.zsh-config/plugins.zsh
source $HOME/.zsh-config/fuzzy-find.zsh
source $HOME/.zsh-config/workspace-navigation.zsh
source $HOME/.zsh-config/nvm.zsh
source $HOME/.zsh-config/tmate.zsh
source ~/.safe-chain/scripts/init-posix.sh # Safe-chain Zsh initialization script

[ -f /home/stevendejong/.config/cani/completions/_cani.zsh ] && source /home/stevendejong/.config/cani/completions/_cani.zsh

# NVM is loaded via ~/.zsh-config/nvm.zsh - no need to load again here
[ -s $HOME/.rsvm/rsvm.sh ] && \. "$HOME/.rsvm/rsvm.sh" # This loads RSVM

eval "$(zoxide init --cmd cd zsh)"

# Lazy load thefuck - only initialize when first used
fuck() {
  unset -f fuck
  eval $(thefuck --alias)
  fuck "$@"
}

export PATH=$PATH:/home/stevendejong/.local/bin

# Claude Profile integration
[ -f ~/.zsh-config/claude-profile.zsh ] && source ~/.zsh-config/claude-profile.zsh

# completions
fpath=(~/.zsh-config/completions $fpath)

# dialog-cli completion
eval "$(register-python-argcomplete --shell zsh dialog-cli)"
