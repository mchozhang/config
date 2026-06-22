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
export DRY_RUN

# ── Home files (leaf-level only) ─────────────────────────────────────────────
# Walk every file under home/ and symlink it into the matching path under ~.
# Never symlink a directory — shared dirs like ~/.local are managed by other tools too.
log-separator "Syncing home files"

while IFS= read -r -d '' src; do
  rel="${src#"$basedir/home/"}"
  dst="$HOME/$rel"
  link "$src" "$dst"
done < <(find "$basedir/home" -type f -print0)

log "Home files synced."
