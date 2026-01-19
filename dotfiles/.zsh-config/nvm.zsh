# NVM configuration with lazy loading for faster shell startup
export NODE_OPTIONS="--max-old-space-size=20480"
export NVM_DIR="$HOME/.nvm"

# Flag to track if NVM has been loaded
_nvm_loaded=0

# Function to actually load NVM
_load_nvm() {
  if [ $_nvm_loaded -eq 0 ]; then
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    _nvm_loaded=1

    # Now that NVM is loaded, activate the smart directory switching
    _activate_nvm_auto_switch
  fi
}

# Early hook to detect .nvmrc before NVM is loaded
_check_nvmrc_and_load() {
  # Quick check for .nvmrc without loading NVM
  if [ $_nvm_loaded -eq 0 ]; then
    # Look for .nvmrc in current directory or parent directories
    local dir="$PWD"
    while [[ "$dir" != "" && "$dir" != "/" ]]; do
      if [[ -f "$dir/.nvmrc" ]]; then
        # Found .nvmrc, load NVM and it will auto-switch
        _load_nvm
        return
      fi
      dir="${dir%/*}"
    done

    # Check for package.json with engines.node
    if [[ -f "$PWD/package.json" ]] && grep -q '"node"' "$PWD/package.json" 2>/dev/null; then
      _load_nvm
      return
    fi
  fi
}

# Smart directory-based Node version switching
_activate_nvm_auto_switch() {
  autoload -U add-zsh-hook

  check_nvm() {
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
        nvm use
      fi
    elif [ -f package.json ]; then
      nodeVersion=$(jq -r '.engines.node | select(.!=null)' package.json )

      if [ ! -z $nodeVersion ] && [[ ! $(nvm current) = "^v$nodeVersion" ]]; then
        echo "found $nodeVersion in package.json engine"
        nvm use ${nodeVersion:0:2}
      fi
    fi
  }

  add-zsh-hook chpwd check_nvm
  check_nvm
}

# Lazy loading wrapper for nvm command
nvm() {
  unset -f nvm node npm npx
  _load_nvm
  nvm "$@"
}

# Lazy loading wrapper for node command
node() {
  unset -f nvm node npm npx
  _load_nvm
  node "$@"
}

# Lazy loading wrapper for npm command
npm() {
  unset -f nvm node npm npx
  _load_nvm
  npm "$@"
}

# Lazy loading wrapper for npx command
npx() {
  unset -f nvm node npm npx
  _load_nvm
  npx "$@"
}

# Activate early .nvmrc detection on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd _check_nvmrc_and_load

# Check on shell startup too
_check_nvmrc_and_load
