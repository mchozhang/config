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

# ── XDG config tools ────────────────────────────────────────────────────────
# Walk every file/symlink under xdg/ and symlink it into the matching path under ~/.config.
# Never symlink a folder — this lets external tools write their own files alongside.
echo "==> XDG"
while IFS= read -r -d '' src; do
  rel="${src#"$basedir/xdg/"}"
  xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  dst="$xdg_config_home/$rel"
  link "$src" "$dst"
done < <(find "$basedir/xdg" \( -type f -o -type l \) -print0)

echo "==> Done"

