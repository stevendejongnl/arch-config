eval "$(fzf --zsh)"

# Load fzf-git.sh for git-specific keybindings (CTRL-G prefix)
source ~/.zplug/repos/junegunn/fzf-git.sh/fzf-git.sh

# Export all the known keymaps with prefix CTRL-g so it can be mapped in tmux
export FZF_GIT_BINDKEYS=$(bindkey -p '^g')
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --exclude .git . "$1"
}
