#!/usr/bin/env bash
# Compiles config.yaml into config.lock.json for use without yq dependency.

set -eu -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$basedir/lib/utils.sh"

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --*) error "unknown argument: $arg"; exit 1 ;;
  esac
done

DRY_RUN="${DRY_RUN:-0}"
export DRY_RUN

if ! command -v yq >/dev/null 2>&1; then
  error "yq is required to build config.lock.json"
  exit 1
fi

output="$basedir/config.lock.json"
if [ "$DRY_RUN" = "1" ]; then
  log "[dry-run] would write: $output"
  yq -o=json "$basedir/config.yaml" | jq
else
  yq -o=json "$basedir/config.yaml" | jq | tee "$output"
  log "built json config at ${basedir}/config.lock.json"
fi
