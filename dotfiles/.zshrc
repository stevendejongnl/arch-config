# Auto-rebuild combined CA bundle if mitmproxy cert has changed
() {
  local mitm_cert=~/.mitmproxy/mitmproxy-ca-cert.pem
  local combined=~/.mitmproxy/combined-ca-bundle.pem
  local fp_file=~/.mitmproxy/.combined-bundle-fingerprint

  if [[ -f "$mitm_cert" ]]; then
    local current_fp=$(openssl x509 -in "$mitm_cert" -noout -fingerprint 2>/dev/null)
    local stored_fp=$(cat "$fp_file" 2>/dev/null)
    if [[ "$current_fp" != "$stored_fp" || ! -f "$combined" ]]; then
      cat "$mitm_cert" /etc/ca-certificates/extracted/tls-ca-bundle.pem > "$combined"
      echo "$current_fp" > "$fp_file"
    fi
    export CURL_CA_BUNDLE="$combined"
  else
    unset CURL_CA_BUNDLE
  fi
}
export ANDROID_HOME=/home/stevendejong/Android/Sdk
export PATH=$HOME/bin:$HOME/.local/bin:$HOME/.local/share/JetBrains/Toolbox/scripts:/usr/local/bin:$HOME/.lmstudio/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

# Also source here (not just .zprofile) so non-login shells (e.g. tools that
# spawn a plain interactive zsh, like Claude Code) still get these vars.
[ -f "$HOME/.auth_tokens" ] && source "$HOME/.auth_tokens"

source $HOME/.zsh-config/autocompletion.zsh
source $HOME/.zsh-config/base.zsh
source $HOME/.zsh-config/sudo.zsh
source $HOME/.zsh-config/plugins.zsh
source $HOME/.zsh-config/fuzzy-find.zsh
source $HOME/.zsh-config/workspace-navigation.zsh
# safe-chain must load BEFORE nvm.zsh: nvm's lazy npm/npx wrappers need to win at
# startup (they trigger the nvm load), and nvm.zsh re-applies safe-chain on top
# once real npm/npx exist. safe-chain binary lives in ~/.npm-global/bin.
export PATH="$HOME/.npm-global/bin:$PATH"
[ -f "$HOME/.safe-chain/scripts/init-posix.sh" ] && source "$HOME/.safe-chain/scripts/init-posix.sh" # Safe-chain
source $HOME/.zsh-config/nvm.zsh
source $HOME/.zsh-config/tmate.zsh
source $HOME/.zsh-config/ollama.zsh

[ -f /home/stevendejong/.config/cani/completions/_cani.zsh ] && source /home/stevendejong/.config/cani/completions/_cani.zsh

# NVM is loaded via ~/.zsh-config/nvm.zsh - no need to load again here
[ -s $HOME/.rsvm/rsvm.sh ] && \. "$HOME/.rsvm/rsvm.sh" # This loads RSVM

[[ -o interactive ]] && eval "$(zoxide init --cmd cd zsh)"

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
command -v register-python-argcomplete >/dev/null && eval "$(register-python-argcomplete --shell zsh dialog-cli)"

fpath+=~/.zfunc
# ponytail: the one compinit call. Rebuild the dump at most once/day; -C skips
# the security audit + recompile on every other startup.
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select

# Claude Code transparency audit — routes through mitmproxy dashboard
alias claude-audit='NODE_EXTRA_CA_CERTS="$HOME/.mitmproxy/mitmproxy-ca-cert.pem" HTTPS_PROXY=http://localhost:8082 claude'

# bun completions
[ -s "/home/stevendejong/.bun/_bun" ] && source "/home/stevendejong/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# sentry
fpath=("/home/stevendejong/.local/share/zsh/site-functions" $fpath)
[ -f "$HOME/.mcp-env" ] && source ~/.mcp-env

gs() {
  local def
  def=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  [ -z "$def" ] && def=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
  [ -z "$def" ] && { echo "no default branch found"; return 1; }
  git reset --hard && git clean -fd && git checkout "$def" && git reset --hard "origin/$def" && git pull --ff-only
}

# Attach to persistent claude session on claude-server (screen, not tmux)
claude-attach() {
  ssh -t claude-server 'screen -dRR claude claude -n "Claude Server"'
}

# arch-config sync check: fetch (throttled to once / few hours) + report if the
# repo is behind origin. Interactive + real terminal only; never blocks or errors
# out a shell. `archsync pull` / `archsync status` for the rest.
if [[ -o interactive && -t 1 ]] && command -v archsync >/dev/null; then
  archsync check || true
fi

# Added by JetBrains Context CLI installer
case ":$PATH:" in
    *":/home/stevendejong/.jbcontext/bin:"*) ;;
    *) export PATH="$PATH:/home/stevendejong/.jbcontext/bin" ;;
esac
