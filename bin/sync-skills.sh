#!/usr/bin/env bash

set -eu -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$basedir/lib/utils.sh"
source "$basedir/lib/install.sh"

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
  esac
done

DRY_RUN="${DRY_RUN:-0}"

tool_paths=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.kiro/skills"
)

log-separator "Syncing global agent skills"

for tool_path in "${tool_paths[@]}"; do
  for skill_dir in "$basedir"/skills/*; do
    [ -f "$skill_dir/SKILL.md" ] || continue

    skill_name="$(basename "$skill_dir")"
    dst_skill_dir="$tool_path/$skill_name"

    if [ -L "$dst_skill_dir" ] && [ "$(readlink "$dst_skill_dir")" = "$skill_dir" ]; then
      log "already linked: $skill_dir → $dst_skill_dir"
    elif [ -e "$dst_skill_dir" ] || [ -L "$dst_skill_dir" ]; then
      # dst_skill_dir is a real file/dir or a symlink pointing elsewhere: replace it
      if [ "$DRY_RUN" = "1" ]; then
        log "[dry-run] would replace existing link: $dst_skill_dir → $skill_dir"
      else
        rm -rf "$dst_skill_dir"
        link "$skill_dir" "$dst_skill_dir"
      fi
    else
      link "$skill_dir" "$dst_skill_dir"
    fi
  done
done

log "Global agent skills synced."
