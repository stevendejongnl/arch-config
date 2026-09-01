# Claude Profile Management with CLAUDE_CONFIG_DIR isolation
# Precedence: shell-local $CLAUDE_PROFILE > project .claude-profile > global active profile

claude() {
  local shell_profile="${CLAUDE_PROFILE:-}"
  local active_profile=$(claude-profile current --short 2>/dev/null)
  local status_profile=$(claude-profile status --short 2>/dev/null)

  local project_profile=""
  [ -n "$status_profile" ] && [ "$status_profile" != "$active_profile" ] && project_profile="$status_profile"

  local effective_profile="${shell_profile:-${project_profile:-$active_profile}}"

  if [ -n "$effective_profile" ]; then
    export CLAUDE_CONFIG_DIR="$HOME/.claude/accounts/$effective_profile"
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
      echo "Warning: $CLAUDE_CONFIG_DIR missing for profile '$effective_profile'" >&2
      unset CLAUDE_CONFIG_DIR
    fi
  fi

  command claude "$@"
}

# Quick switch function with clear instructions
# Unalias first in case it was aliased elsewhere
unalias cpswitch 2>/dev/null
cpswitch() {
  if [ -z "$1" ]; then
    echo "Usage: cpswitch <profile-name>"
    echo ""
    echo "Available profiles:"
    claude-profile list
    return 1
  fi

  claude-profile switch "$1"
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✓ Profile switched to: $1"
    echo ""
    echo "To apply changes:"
    echo "  • For NEW Claude sessions: Just run 'claude' and it will use the new profile"
    echo "  • For EXISTING Claude sessions: Type '/new' in Claude to start a fresh conversation"
    echo ""
    echo "Quick test: Run 'claude /status' to verify"
  fi

  return $exit_code
}

# Aliases for convenience
alias opusplan='claude --model opusplan'
alias cprofile='claude-profile'
alias cplist='claude-profile list'
alias cpstatus='claude-profile status'
alias cpmigrate='claude-profile migrate'
