#!/usr/bin/env bash
set -euo pipefail

remote="origin"
branch="main"
remote_ref="refs/remotes/${remote}/${branch}"
stash_created=0
stash_ref=""
stash_message=""
skill_name="latest-origin-main"
skill_source_rel="codex/skills/${skill_name}"
local_skill_root="${CODEX_SKILLS_DIR:-${CODEX_HOME:-$HOME/.codex}/skills}"
local_skill_dir="${local_skill_root}/${skill_name}"
skill_backup_root="${CODEX_SKILL_SYNC_BACKUP_DIR:-${CODEX_HOME:-$HOME/.codex}/skill-sync-backups}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

print_stash_restore() {
  if [[ "$stash_created" -eq 1 ]]; then
    printf 'Stashed local changes: yes\n'
    printf 'Stash: %s\n' "$stash_ref"
    printf 'Stash message: %s\n' "$stash_message"
    print_stashed_changes
    printf 'Restore command: git stash pop %s\n' "$stash_ref"
  fi
}

print_stashed_changes() {
  if [[ "$stash_created" -eq 1 && -n "$stash_ref" ]]; then
    printf 'Stashed changes:\n'
    git stash show --include-untracked --name-status "$stash_ref" || printf 'Unable to show stashed changes for %s.\n' "$stash_ref"
  fi
}

current_sha() {
  git rev-parse HEAD 2>/dev/null || printf 'unknown'
}

print_movement() {
  local from_branch=$1
  local from_sha=$2
  local to_branch=$3
  local to_sha=$4
  local moved="no"

  if [[ "$from_branch" != "$to_branch" || "$from_sha" != "$to_sha" ]]; then
    moved="yes"
  fi

  printf 'Moved: %s\n' "$moved"
  printf 'Move: %s@%s -> %s@%s\n' "$from_branch" "$from_sha" "$to_branch" "$to_sha"
}

print_movement_so_far() {
  if [[ -n "${original_branch:-}" && -n "${original_sha:-}" ]]; then
    printf 'Movement so far:\n'
    print_movement "$original_branch" "$original_sha" "$(current_branch)" "$(current_sha)"
  fi
}

on_error() {
  local status=$?
  local command=${BASH_COMMAND}

  printf 'ERROR: command failed with exit %s: %s\n' "$status" "$command" >&2
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Current branch: %s\n' "$(current_branch)" >&2
    printf 'Status:\n' >&2
    git status --short --branch >&2 || true
    print_movement_so_far >&2
  fi
  print_stash_restore >&2
  printf 'No destructive cleanup was performed. Resolve the issue, then rerun this script.\n' >&2
  exit "$status"
}

command_failed() {
  local status=$1
  shift

  printf 'ERROR: command failed with exit %s:' "$status" >&2
  printf ' %q' "$@" >&2
  printf '\n' >&2
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Current branch: %s\n' "$(current_branch)" >&2
    printf 'Status:\n' >&2
    git status --short --branch >&2 || true
    print_movement_so_far >&2
  fi
  print_stash_restore >&2
  printf 'No destructive cleanup was performed. Resolve the issue, then rerun this script.\n' >&2
  exit "$status"
}

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  "$@" || command_failed "$?" "$@"
}

git_dir_file() {
  git rev-parse --git-path "$1"
}

stop_if_interrupted_operation() {
  local path

  path=$(git_dir_file MERGE_HEAD)
  if [[ -e "$path" ]]; then
    fail "unfinished merge detected at ${path}; resolve or abort it before syncing main."
  fi

  path=$(git_dir_file rebase-merge)
  if [[ -e "$path" ]]; then
    fail "unfinished rebase detected at ${path}; resolve or abort it before syncing main."
  fi

  path=$(git_dir_file rebase-apply)
  if [[ -e "$path" ]]; then
    fail "unfinished rebase or am detected at ${path}; resolve or abort it before syncing main."
  fi

  path=$(git_dir_file CHERRY_PICK_HEAD)
  if [[ -e "$path" ]]; then
    fail "unfinished cherry-pick detected at ${path}; resolve or abort it before syncing main."
  fi

  path=$(git_dir_file REVERT_HEAD)
  if [[ -e "$path" ]]; then
    fail "unfinished revert detected at ${path}; resolve or abort it before syncing main."
  fi
}

current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD
}

same_directory() {
  local left=$1
  local right=$2
  local left_real
  local right_real

  [[ -d "$left" && -d "$right" ]] || return 1
  left_real=$(cd "$left" && pwd -P) || return 1
  right_real=$(cd "$right" && pwd -P) || return 1
  [[ "$left_real" == "$right_real" ]]
}

sync_local_skill_package() {
  local source_dir=$1
  local target_dir=$2
  local backup_timestamp
  local backup_dir

  if [[ ! -d "$source_dir" ]]; then
    fail "updated skill source directory is missing: ${source_dir}"
  fi

  if [[ -L "$target_dir" ]]; then
    if same_directory "$target_dir" "$source_dir"; then
      printf 'Local skill sync: already synced by symlink at %s\n' "$target_dir"
      return
    fi
    fail "local skill target is a symlink to a different directory: ${target_dir}"
  fi

  if [[ ! -e "$target_dir" ]]; then
    run mkdir -p "$(dirname "$target_dir")"
    run ln -s "$source_dir" "$target_dir"
    printf 'Local skill sync: linked %s -> %s\n' "$target_dir" "$source_dir"
    return
  fi

  if [[ ! -d "$target_dir" ]]; then
    fail "local skill target exists but is not a directory: ${target_dir}"
  fi

  if [[ ! -f "$target_dir/SKILL.md" ]] || ! grep -Eq "^name:[[:space:]]*${skill_name}$" "$target_dir/SKILL.md"; then
    fail "local skill target does not look like ${skill_name}: ${target_dir}"
  fi

  if diff -qr "$source_dir" "$target_dir" >/dev/null 2>&1; then
    printf 'Local skill sync: already up to date at %s\n' "$target_dir"
    return
  fi

  backup_timestamp=$(date -u +"%Y%m%dT%H%M%SZ")-$$
  backup_dir="${skill_backup_root}/${skill_name}/${backup_timestamp}"
  run mkdir -p "$backup_dir"
  run rsync -a "${target_dir}/" "${backup_dir}/"
  run rsync -a --delete "${source_dir}/" "${target_dir}/"
  printf 'Local skill sync: updated %s from %s\n' "$target_dir" "$source_dir"
  printf 'Local skill backup: %s\n' "$backup_dir"
}

sync_local_skill_if_updated() {
  local before_sha=$1
  local after_sha=$2
  local source_dir="${repo_root}/${skill_source_rel}"
  local changed_files

  if [[ ! -d "$source_dir" ]]; then
    printf 'Local skill sync: not applicable; %s is not in this repository.\n' "$skill_source_rel"
    return
  fi

  if [[ -z "$before_sha" || "$before_sha" == "$after_sha" ]]; then
    printf 'Local skill sync: not needed; no %s changes in this update.\n' "$skill_source_rel"
    return
  fi

  changed_files=$(git diff --name-only "$before_sha" "$after_sha" -- "$skill_source_rel")
  if [[ -z "$changed_files" ]]; then
    printf 'Local skill sync: not needed; no %s changes in this update.\n' "$skill_source_rel"
    return
  fi

  printf 'Updated skill files:\n'
  printf '%s\n' "$changed_files"
  sync_local_skill_package "$source_dir" "$local_skill_dir"
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || fail "current directory is not inside a Git worktree."
cd "$repo_root"
trap on_error ERR

original_branch=$(current_branch)
original_sha=$(current_sha)
printf 'Repository: %s\n' "$repo_root"
printf 'Original branch: %s\n' "$original_branch"
printf 'Original commit: %s\n' "$original_sha"
printf 'Initial status:\n'
git status --short --branch

stop_if_interrupted_operation

if ! git remote get-url "$remote" >/dev/null 2>&1; then
  fail "remote '${remote}' is not configured."
fi

run git fetch "$remote" --prune

if ! git rev-parse --verify --quiet "$remote_ref" >/dev/null; then
  fail "${remote}/${branch} does not exist after fetching."
fi

if [[ -n "$(git status --porcelain)" ]]; then
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  stash_message="latest-origin-main: ${original_branch} ${timestamp}"
  run git stash push -u -m "$stash_message"
  stash_created=1
  stash_ref=$(git stash list --format='%gd' -n 1)
  printf 'Created stash: %s (%s)\n' "$stash_ref" "$stash_message"
else
  printf 'No local changes to stash.\n'
fi

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  run git switch "$branch"
else
  run git switch --track -c "$branch" "${remote}/${branch}"
fi

main_before_update_sha=$(current_sha)
run git merge --ff-only "${remote}/${branch}"

head_sha=$(git rev-parse HEAD)
remote_sha=$(git rev-parse "$remote_ref")
final_status=$(git status --porcelain)

if [[ "$head_sha" != "$remote_sha" ]]; then
  fail "HEAD (${head_sha}) does not match ${remote}/${branch} (${remote_sha}) after fast-forward."
fi

if [[ -n "$final_status" ]]; then
  printf '%s\n' "$final_status" >&2
  fail "worktree is not clean after syncing ${remote}/${branch}."
fi

printf '\nDone.\n'
final_branch=$(current_branch)
printf 'Final branch: %s\n' "$final_branch"
printf 'Final commit: %s\n' "$head_sha"
print_movement "$original_branch" "$original_sha" "$final_branch" "$head_sha"
printf 'HEAD matches %s/%s: yes\n' "$remote" "$branch"
sync_local_skill_if_updated "$main_before_update_sha" "$head_sha"

if [[ "$stash_created" -eq 1 ]]; then
  print_stash_restore
else
  printf 'Stashed local changes: no\n'
fi
