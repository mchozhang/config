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

tools=$(get-config -re '[
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
skipped=()

os="$(get-os)"

while IFS= read -r tool; do
  log ""
  log-separator "$tool"
  result=0
  "$basedir/bin/install-tool.sh" "$tool" || result=$?
  if [ $result -eq 1 ]; then
    warn "Failed to install: $tool"
    failed+=("$tool")
  elif [ $result -eq 2 ]; then
    skipped+=("$tool")
  else
    log "$tool installed successfully"
  fi
done <<< "$tools"

if [ "${#failed[@]}" -gt 0 ] || [ "${#skipped[@]}" -gt 0 ]; then
  if [ "${#skipped[@]}" -gt 0 ]; then
    warn "The following tools were skipped to install: ${skipped[*]}"
  fi
  if [ "${#failed[@]}" -gt 0 ]; then
    warn "The following tools were failed to install: ${failed[*]}"
  fi
  log-separator "done (with errors)"
  exit 1
fi
