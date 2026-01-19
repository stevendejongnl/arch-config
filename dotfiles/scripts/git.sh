#! /bin/sh

_delete_local_branches() {
  if git rev-parse --verify master &>/dev/null; then
    git checkout master || return 1
  elif git rev-parse --verify main &>/dev/null; then
    git checkout main || return 1
  else
    return 1
  fi

  git fetch --prune

  local branches_to_delete
  branches_to_delete=$(git branch --format="%(refname:short)" | while read branch; do
    if ! git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
      echo "$branch"
    fi
  done)

  if [[ -z "$branches_to_delete" ]]; then
    return 0
  fi

  local selected_branches
  selected_branches=$(echo "$branches_to_delete" | fzf --multi --height=80% --border --ansi \
    --header="Use CTRL+A to select all, SPACE to toggle, ENTER to confirm" \
    --preview="git log --oneline {}" \
    --bind "ctrl-a:select-all,ctrl-d:deselect-all,space:toggle")

  if [[ -z "$selected_branches" ]]; then
    return 0
  fi

  echo "$selected_branches" | while read branch; do
    git branch -d "$branch" || echo "Failed to delete branch: $branch"
  done
}

alias delete_local_branches="_delete_local_branches"
