config_home="${CONFIG_HOME:-$HOME/opt/config}"
source "$config_home/lib/utils.sh"

execute-bootstrap-cmd() {
  # Usage: execute-bootstrap <command_string>
  if [ "$#" -ne 1 ]; then
    error "usage: execute-bootstrap <command_string>"
    return 1
  fi

  local cmd="$1"
  if [ -z "$cmd" ] || [ "$cmd" = "null" ]; then
    return 0
  fi

  eval "$cmd"
}

bootstrap-all-tools() {
  local os
  local tools
  os="$(get-os)"

  # Parse all enabled tools with bootstrap defined, sorted by bootstrap-priority, get compact json of a tool in each line
  tools=$(get-config -rce '
    [
      .tools[] |
      select(.enabled != false and .bootstrap != null) |
      { name, bootstrap, priority: (."bootstrap-priority" // 100) }
    ] |
    sort_by(.priority, .name) | .[]'
  )

  while read -r tool; do
    execute-bootstrap-cmd "$(jq -r --arg os "$os" '.bootstrap[$os] // .bootstrap["default"] // empty' <<< "$tool")"
  done <<< "$tools"
}

bootstrap-all-tools
