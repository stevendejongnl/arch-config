#!/usr/bin/env zsh
# Workspace navigation - minimal shell wrapper that delegates to Python

# Main ws function - delegates to Python tool
ws() {
  case "$1" in
    # Help shortcuts
    -h)
      command ws --help
      ;;
    # Global Typer options - pass to main app
    --install-completion|--show-completion|--version|--help)
      command ws "$@"
      ;;
    # List shorthand
    -l|--list)
      command ws --list
      ;;
    # Organization shorthand - pass remaining args to organizer
    -o|--organize)
      shift
      command ws --organize "$@"
      ;;
    # Navigation (default) - eval Python output (cd + tmux rename)
    *)
      eval "$(command ws --shell "$@")"
      ;;
  esac
}
