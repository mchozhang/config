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
  local steps
  os="$(get-os)"

  # Flatten all bootstrap steps across enabled tools, sorted by priority then name
  # shellcheck disable=SC2016
  steps=$(get-config -rce '
    [
      .tools[] |
      select(.enabled != false and .bootstrap != null) |
      .name as $name |
      .bootstrap[] |
      . + { name: $name, priority: (.priority // 100) }
    ] |
    sort_by(.priority, .name) | .[]'
  )

  while read -r step; do
    execute-bootstrap-cmd "$(jq -r --arg os "$os" '.[$os] // .["default"] // empty' <<< "$step")"
  done <<< "$steps"
}

bootstrap-all-tools
