#!/bin/bash

function mosaic_check_branch_add_changes() {
  echo "Checking for changes in the working directory..."
  if [[ -n $(git status --porcelain) ]]; then
    echo "Unstaged changes detected. Running 'git add -p'..."
    git add -p
    if [[ $? -ne 0 ]]; then
      echo "'git add -p' was interrupted or failed. No changes were staged."
      return 1
    fi
    echo "Changes successfully staged."
    return 2
  fi

  local current_branch
  current_branch=$(git branch --show-current)

  if [[ "$current_branch" == "master" || "$current_branch" == "main" ]]; then
    echo "Current branch is 'master' or 'main'. No further action required."
    return 0
  fi

  echo "No changes detected. Checking out 'master' and deleting the current branch..."
  git checkout master || return 1

  echo "Are you sure you want to delete the branch '$current_branch'? [y/N]"
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    git branch -d "$current_branch" || return 1
    echo "Branch '$current_branch' has been deleted."
  else
    echo "Branch deletion canceled."
  fi

  return 0
}

function mosaic_run_update_and_push() {
  mosaic_update || return 1
  mosaic_check_branch_add_changes
  local check_status=$?

  if [[ $check_status -eq 0 ]]; then
    mosaic_push_update
  elif [[ $check_status -eq 2 ]]; then
    echo "Changes were staged but not pushed. Exiting."
    return 0
  else
    echo "An error occurred during the process."
    return 1
  fi
}

function mosaic_update() {
  echo "Switching to 'master' branch and pulling the latest changes..."
  git switch master
  git pull

  local branch_name
  branch_name=MOS-368_$(date +'%Y-%m-%d')_node_dependency_updates

  if git show-ref --verify --quiet refs/heads/"$branch_name"; then
    echo "Branch '$branch_name' already exists. Switching to it..."
    git switch "$branch_name"
  else
    echo "Branch '$branch_name' does not exist. Creating and switching to it..."
    git switch -c "$branch_name"
  fi

  echo "Running 'npm run upgrade' to update dependencies..."
  npm run upgrade
}

function mosaic_push_update() {
  local current_dir
  local parent_dir
  local current_dir_name

  current_dir=$(pwd)
  parent_dir=$(basename "$(dirname "$current_dir")")
  current_dir_name=$(basename "$current_dir")

  echo "Preparing to push updates for directory: ${parent_dir}/${current_dir_name}"

  if [[ "$current_dir_name" == "shared" && "$parent_dir" == "mosaic" ]]; then
    git commit -m "fix(dependencies): weekly update ($(date +'%Y-%m-%d'))"
    git push --set-upstream origin MOS-368_$(date +'%Y-%m-%d')_node_dependency_updates \
      -o merge_request.create \
      -o merge_request.title="fix(dependencies): weekly update ($(date +'%Y-%m-%d'))" \
      -o merge_request.description="MOS-368  \n  \nCloses #1" \
      -o merge_request.merge_when_pipeline_succeeds
  else
    git commit -m "chore(dependencies): weekly update ($(date +'%Y-%m-%d'))"
    git push --set-upstream origin MOS-368_$(date +'%Y-%m-%d')_node_dependency_updates \
      -o merge_request.create \
      -o merge_request.title="chore(dependencies): weekly update ($(date +'%Y-%m-%d'))" \
      -o merge_request.description="MOS-368  \n  \nCloses #1" \
      -o merge_request.merge_when_pipeline_succeeds
  fi

  echo "Update successfully pushed!"
  cat << "EOF"
  _____   ____  _   _ ______ 
 |  __ \ / __ \| \ | |  ____|
 | |  | | |  | |  \| | |__   
 | |  | | |  | | . ` |  __|  
 | |__| | |__| | |\  | |____ 
 |_____/ \____/|_| \_|______|
EOF
}

function mosaic() {
  tmux new-window -c ~/workspace/cloudsuite/mosaic/eslint-plugins/ \; \
    split-window -h -c ~/workspace/cloudsuite/mosaic/shared/ \; \
    select-pane -t 1 \; \
    split-window -v -c ~/workspace/cloudsuite/mosaic/elements/ \; \
    select-pane -t 3 \; \
    split-window -v -c ~/workspace/cloudsuite/mosaic/components/
}

function mosaic_updates() {
  tmux new-window -c ~/workspace/cloudsuite/mosaic/eslint-plugins/ \; \
    send-keys 'mosaic_run_update_and_push' C-m \; \
    split-window -h -c ~/workspace/cloudsuite/mosaic/shared/ \; \
    send-keys 'mosaic_run_update_and_push' C-m \; \
    select-pane -t 1 \; \
    split-window -v -c ~/workspace/cloudsuite/mosaic/elements/ \; \
    send-keys 'mosaic_run_update_and_push' C-m \; \
    select-pane -t 3 \; \
    split-window -v -c ~/workspace/cloudsuite/mosaic/components/ \; \
    send-keys 'mosaic_run_update_and_push' C-m
}

alias mosaic_update="mosaic_update"
alias mosaic_push_update="mosaic_push_update"
alias mosaic="mosaic"
alias mosaic_updates="mosaic_updates"
alias mosaic_check_branch_add_changes="mosaic_check_branch_add_changes"
alias mosaic_run_update_and_push="mosaic_run_update_and_push"
