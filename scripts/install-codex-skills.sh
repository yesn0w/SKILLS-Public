#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/install-codex-skills.sh [--dry-run]

Symlink Codex skills from this repository into ${CODEX_SKILLS_DIR:-$HOME/.codex/skills}.

Options:
  --dry-run   Print planned actions without changing the filesystem.
  -h, --help  Show this help.
USAGE
}

dry_run=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      dry_run=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd "$script_dir/.." && pwd -P)
source_dir="$repo_root/codex/skills"
target_dir="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"

if [[ ! -d "$source_dir" ]]; then
  echo "Missing source directory: $source_dir" >&2
  exit 1
fi

run() {
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run mkdir -p "$target_dir"

found=0
for skill_dir in "$source_dir"/*; do
  [[ -d "$skill_dir" ]] || continue
  found=1

  skill_name=$(basename "$skill_dir")
  target="$target_dir/$skill_name"

  if [[ -L "$target" ]]; then
    current=$(readlink "$target")
    if [[ "$current" == "$skill_dir" ]]; then
      echo "Already linked: $target -> $skill_dir"
      continue
    fi
    echo "Refusing to replace existing symlink: $target -> $current" >&2
    exit 1
  fi

  if [[ -e "$target" ]]; then
    echo "Refusing to overwrite existing path: $target" >&2
    echo "Move it aside or remove it manually, then rerun this installer." >&2
    exit 1
  fi

  run ln -s "$skill_dir" "$target"
  echo "Linked: $target -> $skill_dir"
done

if [[ "$found" -eq 0 ]]; then
  echo "No skills found in: $source_dir" >&2
  exit 1
fi

echo "Codex skills install complete. Restart Codex or open a new session to rediscover skills."
