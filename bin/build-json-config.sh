#!/usr/bin/env bash
# Builds config.lock.json by merging tools from config.yaml and config.local.yaml.

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
base_config="$basedir/config.yaml"
input_files=("$base_config")

for f in "$basedir"/config.*.yaml; do
  [ -f "$f" ] && input_files+=("$f")
done

# Filter disabled config files, sort descending by priority (so lower number = higher priority wins last via INDEX).
# yq emits one JSON document per input file; jq performs cross-file merge.
merge_jq_expr='map(select(.enabled != false))
  | sort_by(.priority // 100) | reverse
  | map(.tools // [])
  | add // []
  | { tools: [INDEX(.[]; .name)[]] }'

if [ "$DRY_RUN" = "1" ]; then
  log "[dry-run] would write: $output"
  yq ea -o=json '.' "${input_files[@]}" | jq -s "$merge_jq_expr"
else
  yq ea -o=json '.' "${input_files[@]}" | jq -s "$merge_jq_expr" | tee "$output"
  log "built json config at ${basedir}/config.lock.json"
fi
