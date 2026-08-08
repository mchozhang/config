

# blue
log() { ( set +x; printf '\e[1;34m%s\e[m\n' "$*" ) >&2; }

# yellow
warn() { ( set +x; printf '\e[1;33m%s\e[m\n' "$*" ) >&2; }

# red
error() { ( set +x; printf '\e[1;31m%s\e[m\n' "$*" ) >&2; }

get-os() {
  case "$(uname -s)" in
    Darwin) echo "macos"; return ;;
  esac

  if [ -f /etc/os-release ]; then
    # ID field maps directly to our supported names for most distros
    local id
    id=$(. /etc/os-release && echo "${ID:-}")
    case "$id" in
      ubuntu) echo "ubuntu"  ;;
      debian) echo "debian"  ;;
      alpine) echo "alpine"  ;;
      arch) echo "arch"    ;;
      rhel|centos|fedora|rocky|almalinux) echo "redhat" ;;
      *) error "unsupported os: $id"; return 1 ;;
    esac
  else
    error "cannot determine os: /etc/os-release not found"; return 1
  fi
}

get-config() {
  # Usage: get-config [<jq_expression> [jq_args...]]  (defaults to '.' for full document)
  local config_dir
  # bash: BASH_SOURCE[0] is the sourced file; zsh: BASH_SOURCE[0] is always empty use print -P '%x' instead
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    config_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    config_dir="$(cd "$(dirname "$(print -P '%x')")/.." && pwd)"
  fi

  if [ -f "$config_dir/config.lock.json" ]; then
    jq "${@:-.}" "$config_dir/config.lock.json"
  elif command -v yq >/dev/null; then
    local config_files=("$config_dir/config.yaml")

    # In zsh, avoid nomatch errors when config.*.yaml doesn't exist.
    if [ -n "${ZSH_VERSION:-}" ]; then
      setopt local_options nonomatch
    fi

    for f in "$config_dir"/config.*.yaml; do
      [ -f "$f" ] && config_files+=("$f")
    done

    # Filter disabled config files, sort descending by priority (so lower number = higher priority wins last via INDEX).
    # yq emits one JSON document per input file; jq performs cross-file merge.
    merge_jq_expr='map(select(.enabled != false))
      | sort_by(.priority // 100) | reverse
      | map(.tools // [])
      | add // []
      | { tools: [INDEX(.[]; .name)[]] }'

    yq ea -o=json '.' "${config_files[@]}" | jq -s "$merge_jq_expr" | jq "${@:-.}"
  else
    error "no config file found, looked for: $config_dir/config.lock.json, $config_dir/config.yaml, or $config_dir/config.*.yaml."
    return 1
  fi
}

get-tool-config() {
  # Usage: get-tool-config <tool> [<jq_expression> [jq_args...]]  (defaults to '.' for full document)
  local tool="$1"; shift
  get-config ".tools[] | select(.name==\"$tool\")" | jq "${@:-.}"
}

log-separator() {
  # Usage: log-separator [label]
  local label="${1:-}"
  local width=50
  if [ -n "$label" ]; then
    local pad=$(( (width - ${#label} - 2) / 2 ))
    local line
    line="$(printf '%*s' "$pad" '' | tr ' ' '-')"
    log "${line} ${label} ${line}"
  else
    log "$(printf '%*s' "$width" '' | tr ' ' '-')"
  fi
}
