# Claude Profile Management with CLAUDE_CONFIG_DIR isolation
# Auto-switch profile based on .claude-profile in project

# Track the last used profile to detect changes
_CLAUDE_LAST_PROFILE=""

# Wrapper function for claude command
claude() {
  # Check for project-specific profile
  local project_profile=$(claude-profile status --short 2>/dev/null)
  local active_profile=$(claude-profile current --short 2>/dev/null)

  # Auto-switch if project profile differs from active
  if [ -n "$project_profile" ] && [ "$project_profile" != "$active_profile" ]; then
    echo "Switching Claude profile to: $project_profile" >&2
    if ! claude-profile switch "$project_profile" 2>&1 | sed 's/^/  /'; then
      echo "Failed to switch profile, using active profile: $active_profile" >&2
      project_profile="$active_profile"
    fi
  fi

  # Determine effective profile (project override or active)
  local effective_profile="${project_profile:-$active_profile}"

  # Check if profile changed since last run
  if [ -n "$_CLAUDE_LAST_PROFILE" ] && [ "$_CLAUDE_LAST_PROFILE" != "$effective_profile" ]; then
    echo "Profile changed from $_CLAUDE_LAST_PROFILE to $effective_profile" >&2
    echo "Note: If you're in an active Claude session, you may need to start a new conversation" >&2
    echo "      to pick up the new authentication. Use 'claude /new' or exit and restart." >&2
  fi
  _CLAUDE_LAST_PROFILE="$effective_profile"

  # Set CLAUDE_CONFIG_DIR to point to account directory
  if [ -n "$effective_profile" ]; then
    export CLAUDE_CONFIG_DIR="$HOME/.claude/accounts/$effective_profile"

    # Verify account directory exists
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
      echo "Warning: Account directory not found for profile '$effective_profile'" >&2
      echo "Run 'claude-profile migrate' to set up account isolation" >&2
      unset CLAUDE_CONFIG_DIR
    fi
  fi

  # Run actual claude command with isolated config
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
alias cprofile='claude-profile'
alias cplist='claude-profile list'
alias cpstatus='claude-profile status'
alias cpmigrate='claude-profile migrate'
