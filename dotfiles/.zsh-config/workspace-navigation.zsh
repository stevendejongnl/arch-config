#!/usr/bin/env zsh
# Workspace navigation tool - quickly jump to projects across workspace

# Get all projects by searching for .git directories
_ws_get_projects() {
  local workspace_root="/home/stevendejong/workspace"

  # Helper function to extract project path from .git directory
  _extract_project() {
    local gitdir="$1"
    # Remove /.git/ suffix
    local project="${gitdir%/.git/}"
    # Remove workspace root prefix
    echo "${project#$workspace_root/}"
  }

  # Find all git repositories (actual projects) across all areas
  {
    # CloudSuite: search up to 5 levels deep (handles monorepos like mosaic)
    while IFS= read -r gitdir; do
      [[ -n "$gitdir" ]] && _extract_project "$gitdir"
    done < <(fd -t d --max-depth 5 --no-ignore-vcs -H '^\.git$' "$workspace_root/cloudsuite" 2>/dev/null)

    # Personal: search up to 5 levels deep (handles nested projects)
    while IFS= read -r gitdir; do
      [[ -n "$gitdir" ]] && _extract_project "$gitdir"
    done < <(fd -t d --max-depth 5 --no-ignore-vcs -H '^\.git$' "$workspace_root/personal" 2>/dev/null)

    # Builds: search up to 3 levels deep (flat + potential nesting)
    while IFS= read -r gitdir; do
      [[ -n "$gitdir" ]] && _extract_project "$gitdir"
    done < <(fd -t d --max-depth 3 --no-ignore-vcs -H '^\.git$' "$workspace_root/builds" 2>/dev/null)
  } | sort
}

# Fuzzy search mode - search for projects by name
_ws_fuzzy_search() {
  local query="$1"
  local workspace_root="/home/stevendejong/workspace"

  # Get all projects and filter by query
  local matches=$(_ws_get_projects | fzf --filter="$query")

  # Handle empty result
  if [[ -z "$matches" ]]; then
    echo "No projects match: $query" >&2
    return 1
  fi

  local match_count=$(echo "$matches" | wc -l)

  # Single match - auto navigate
  if [[ $match_count -eq 1 ]]; then
    local target="$workspace_root/$matches"
    if [[ -d "$target" ]]; then
      cd "$target"
      _ws_rename_tmux_window "$target"
      return 0
    else
      echo "Error: Directory not found: $target" >&2
      return 1
    fi
  fi

  # Multiple matches - interactive fzf picker
  local selected=$(echo "$matches" | fzf --height=50% --prompt="Select project: " --no-multi)
  if [[ -n "$selected" ]]; then
    local target="$workspace_root/$selected"
    cd "$target"
    _ws_rename_tmux_window "$target"
    return 0
  fi
}


# Rename tmux window to directory name (only if 1 pane in window)
_ws_rename_tmux_window() {
  local target_dir="$1"
  local window_name=$(basename "$target_dir")

  # Check if we're in tmux
  if [[ -z "$TMUX" ]]; then
    return 0
  fi

  # Count panes in current window only
  local pane_count=$(tmux list-panes -t "${TMUX_PANE%:*}" | wc -l)

  # Only rename if exactly 1 pane
  if [[ $pane_count -eq 1 ]]; then
    tmux rename-window "$window_name"
  fi
}

# Categorized browser mode - navigate via menu structure
_ws_categorized_browser() {
  local workspace_root="/home/stevendejong/workspace"

  # Step 1: Select workspace area
  local area=$(printf "cloudsuite\npersonal\nbuilds" | \
    fzf --prompt="Select area: " --height=40%)

  if [[ -z "$area" ]]; then
    return 1
  fi

  # Step 2: Get all projects in the selected area and search through them
  local project=$(_ws_get_projects | grep "^$area/" | \
    fzf --prompt="Search projects in $area: " --height=50%)

  if [[ -n "$project" ]]; then
    local target="$workspace_root/$project"
    cd "$target"
    _ws_rename_tmux_window "$target"
    return 0
  fi

  return 1
}

# Main ws command
ws() {
  case "$1" in
    "")
      # No arguments - categorized browser
      _ws_categorized_browser
      ;;
    -l|--list)
      # List all projects
      _ws_get_projects
      ;;
    -h|--help)
      # Show help
      cat << 'EOF'
ws - Workspace navigation tool with searchable browsing

Usage:
  ws                    Browse: select area → search all projects in area
  ws <query>            Fuzzy search projects (auto-cd if single match)
  ws -l, --list         List all projects
  ws -h, --help         Show this help message

Examples:
  ws                    # Select area, then search all projects in it
  ws mosaic             # Jump directly to mosaic project
  ws components         # Jump directly to components (in mosaic)
  ws -l                # List all 110+ projects

Workflow:
  1. Select area:       cloudsuite / personal / builds
  2. Search projects:   Type to filter all projects in that area
                       Examples: "frontend", "mosaic", "components"

Features:
  • Browse by area first (cloudsuite/personal/builds)
  • Full-text search across all projects in selected area
  • Searches through full paths: cloudsuite/frontend/mosaic/components
  • Fuzzy search: quick project lookup across all projects

Tips:
  • Type while in fzf to search/filter
  • Press Ctrl-C to cancel and go back
  • Zoxide tracks visits for autocomplete
EOF
      ;;
    *)
      # Fuzzy search mode with query
      _ws_fuzzy_search "$*"
      ;;
  esac
}
