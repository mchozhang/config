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
  os="$(get-os)"

  # Flatten all bootstrap steps across enabled tools, sorted by priority then name
  local raw_steps
  # shellcheck disable=SC2016
  raw_steps=$(get-config -rce '
    [
      .tools[] |
      select(.enabled != false and .bootstrap != null) |
      .name as $name |
      .bootstrap[] |
      . + { name: $name, priority: (.priority // 100) }
    ] |
    sort_by(.priority, .name) | .[]'
  )

  # Convert raw_steps into an array
  # keep stdin (TTY) intact for each bootstrap command.
  local -a steps_arr
  while IFS= read -r line; do
    [ -n "$line" ] && steps_arr+=("$line")
  done <<< "$raw_steps"

  for step in "${steps_arr[@]}"; do
    execute-bootstrap-cmd "$(jq -r --arg os "$os" '.[$os] // .["default"] // empty' <<< "$step")"
  done
}

bootstrap-all-tools
