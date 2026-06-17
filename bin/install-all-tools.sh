#!/usr/bin/env bash
# Installs all enabled tools from config.yaml in install-priority order

set -eu -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$basedir/lib/utils.sh"

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
  esac
done

DRY_RUN="${DRY_RUN:-0}"
export DRY_RUN

tools=$(get-config -r '[
  .tools[] |
  select(.enabled != false) |
  select(.install != null)] |
  sort_by(.["install-priority"] // 100) |
  .[].name'
)

if [ -z "$tools" ]; then
  log "No installable tools found in config.yaml"
  exit 0
fi

failed=()

while IFS= read -r tool; do
  log ""
  log-separator "$tool"
  if ! "./$basedir/bin/install-tool.sh" "$tool"; then
    warn "Failed to install: $tool"
    failed+=("$tool")
  fi
done <<< "$tools"

if [ "${#failed[@]}" -gt 0 ]; then
  error "The following tools failed to install: ${failed[*]}"
  log-separator "done (with errors)"
  exit 1
fi
