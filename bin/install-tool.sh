#!/usr/bin/env bash

# todo: add -f|--force to force install even if not enabled
set -eu -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$basedir/lib/utils.sh"
source "$basedir/lib/install.sh"

tool=""

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1;;
    --*) error "unknown argument: $arg"; exit 1 ;;
    *) tool="$arg" ;;
  esac
done

DRY_RUN="${DRY_RUN:-0}"
export DRY_RUN

os="$(get-os)"


if [ -z "$tool" ]; then
  error "usage: $0 [--dry-run|-n] [tool-name]"
  exit 1
fi

tool_config="$(get-tool-config "$tool")"
enabled="$(jq -re '.enabled // true' <<< "$tool_config")"
install_cmd="$(jq -re --arg os "$os" '.install[$os] // .install["default"] // empty' <<< "$tool_config")"

if [ "$enabled" != "true" ]; then
  log "skipping $tool (disabled)"
  exit 0
fi

if [ -z "$install_cmd" ]; then
  error "no install command for $tool on $os"
  exit 1
fi


log "installing/upgrading $tool"

eval "$install_cmd"

log "$tool installation/upgrade complete"
