SPACESHIP_TIME_SHOW=true
SPACESHIP_DIR_TRUNC_REPO=false
SPACESHIP_PROMPT_ASYNC=false
SPACESHIP_EXEC_TIME_ELAPSED=1

SPACESHIP_PROMPT_ORDER=(
  time          # Time stampts section
  exec_time     # Execution time
  user          # Username section
  host          # Hostname section
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  node          # Node.js section
  python        # Python version
  venv          # virtualenv section
  package       # Project version from package.json/pyproject.toml
  pkgmgr        # Package manager (custom section)
  # ruby          # Ruby section
  # xcode         # Xcode section
  # swift         # Swift section
  # golang        # Go section
  docker        # Docker section
  # pyenv         # Pyenv section
  line_sep      # Line break
  # vi_mode       # Vi-mode indicator
  char          # Prompt character
)

# Fix for async worker race condition
# Override spaceship::worker::init with retry mechanism
# This ensures the zpty pseudoterminal is fully initialized before sending commands
spaceship::worker::init() {
  if spaceship::is_prompt_async; then
    SPACESHIP_JOBS=()
    # Only stop worker if it actually exists
    if [[ -n "${ASYNC_PTYS[spaceship]}" ]]; then
      async_stop_worker "spaceship"
    fi
    async_start_worker "spaceship" -n -u

    # Wait for worker to be ready with retry mechanism
    local max_attempts=20
    local attempt=0
    while (( attempt < max_attempts )); do
      # Check if worker exists in ASYNC_PTYS array
      if [[ -n "${ASYNC_PTYS[spaceship]}" ]]; then
        # Worker exists, safe to send commands
        async_worker_eval "spaceship" setopt extendedglob 2>/dev/null || true
        async_worker_eval "spaceship" spaceship::worker::renice 2>/dev/null || true
        async_register_callback "spaceship" spaceship::core::async_callback
        return 0
      fi
      sleep 0.01  # 10ms between attempts
      (( attempt++ ))
    done

    # If we get here, worker failed to start - fall back gracefully
    # Don't send commands to non-existent worker
  fi
}

# Also override spaceship::worker::eval to check worker exists first
spaceship::worker::eval() {
  if spaceship::is_prompt_async; then
    # Only eval if worker actually exists
    if [[ -n "${ASYNC_PTYS[spaceship]}" ]]; then
      async_worker_eval "spaceship" "$@" 2>/dev/null || true
    fi
  fi
}

# ------------------------------------------------------------------------------
# Custom Package Manager Section
# Shows which Python package manager is in use (uv, poetry, pipenv, pip)
# ------------------------------------------------------------------------------

SPACESHIP_PKGMGR_SHOW="${SPACESHIP_PKGMGR_SHOW=true}"
SPACESHIP_PKGMGR_ASYNC="${SPACESHIP_PKGMGR_ASYNC=true}"
SPACESHIP_PKGMGR_PREFIX="${SPACESHIP_PKGMGR_PREFIX="via "}"
SPACESHIP_PKGMGR_SUFFIX="${SPACESHIP_PKGMGR_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_PKGMGR_COLOR="${SPACESHIP_PKGMGR_COLOR="cyan"}"

spaceship_pkgmgr() {
  [[ $SPACESHIP_PKGMGR_SHOW == false ]] && return

  # Only show in Python projects
  local pyproject_toml="$(spaceship::upsearch pyproject.toml)"
  local has_python_files="$(spaceship::upsearch requirements.txt Pipfile setup.py)"

  [[ -z "$pyproject_toml" && -z "$has_python_files" ]] && return

  local pkgmgr_name pkgmgr_symbol

  # Check for UV (highest priority - modern tool)
  if [[ -n "$pyproject_toml" ]]; then
    local pyproject_dir="$(dirname $pyproject_toml)"
    # Check for [tool.uv] in pyproject.toml or uv.lock file
    if grep -q "^\[tool\.uv\]" "$pyproject_toml" 2>/dev/null || \
       [[ -f "$pyproject_dir/uv.lock" ]]; then
      pkgmgr_name="uv"
      pkgmgr_symbol="📦"
    # Check for Poetry
    elif grep -q "^\[tool\.poetry\]" "$pyproject_toml" 2>/dev/null; then
      pkgmgr_name="poetry "
      pkgmgr_symbol="📜"
    fi
  fi

  # Check for Pipenv
  if [[ -z "$pkgmgr_name" ]] && spaceship::upsearch -s Pipfile >/dev/null 2>&1; then
    pkgmgr_name="pipenv "
    pkgmgr_symbol="📦"
  fi

  # Fallback to pip
  if [[ -z "$pkgmgr_name" ]] && [[ -n "$has_python_files" ]]; then
    pkgmgr_name="pip "
    pkgmgr_symbol="🐍"
  fi

  [[ -z "$pkgmgr_name" ]] && return

  spaceship::section \
    --color "$SPACESHIP_PKGMGR_COLOR" \
    --prefix "$SPACESHIP_PKGMGR_PREFIX" \
    --suffix "$SPACESHIP_PKGMGR_SUFFIX" \
    --symbol "$pkgmgr_symbol " \
    "$pkgmgr_name"
}
