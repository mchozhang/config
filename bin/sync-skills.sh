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

destinations=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.kiro/skills"
)

log-separator "Syncing global agent skills"

for destination in "${destinations[@]}"; do
  for skill_dir in "$basedir"/skills/*; do
    [ -f "$skill_dir/SKILL.md" ] || continue

    skill_name="$(basename "$skill_dir")"
    dst="$destination/$skill_name"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$skill_dir" ]; then/
      log "already linked: $skill_dir → $dst"
    elif [ -e "$dst" ] || [ -L "$dst" ]; then
      warn "skipping existing path: $dst"
    else
      link "$skill_dir" "$dst"
    fi
  done
done

log "Global agent skills synced."
