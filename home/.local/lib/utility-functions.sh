# purple
log() { ( set +x; printf '\e[1;35m%s\e[m\n' "$*" ) >&2; }

# yellow
warn() { ( set +x; printf '\e[1;33m%s\e[m\n' "$*" ) >&2; }

# red
error() { ( set +x; printf '\e[1;31m%s\e[m\n' "$*" ) >&2; }

alias //='() { set -o localoptions -o extendedglob; echo $(( "${${history[${(%):-%h}]##[[:blank:]]#}##// }" )); } #'
pi="$(( acos(0) * 2 ))"

calc() {
	expression=$(echo "$*" | gsed 's/\*\*/\^/g')
    echo "$expression" | bc -l
}

no-pyve() {
    if pyve="$VIRTUAL_ENV" && [[ -n "$VIRTUAL_ENV" ]] && [[ ! "$VIRTUAL_ENV" =~ "$PYTHONPATH" ]] && command -v deactivate &>/dev/null; then
        deactivate
    fi

	source "$PYTHONPATH/activate"

    # Set trap to restore venv on exit from this function
    trap '[[ -n "$pyve" ]] && source "$pyve/bin/activate"' EXIT
    "$@"
}

whenis() {
	if ! [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]
	then
		date -d "$@"
	elif (( $1 > 1000000000*1000*1000 ))
	then
		date -d "@${1::-6}.${1:${#1}-6}" "${@:2}"
	elif (( $1 > 1000000000*1000 ))
	then
		date -d "@${1::-3}.${1:${#1}-3}" "${@:2}"
	else
		date -d "@$@"
	fi
}

sumup() {
  jq -s 'add'
}

join() {
  local delimiter="$1"
  shift

  local input=()

  if [ -t 0 ]; then
    # No stdin — use command-line arguments
    input=("$@")
  else
    if [ -n "$ZSH_VERSION" ]; then
      # Zsh: use ${(f)...} to split stdin by line (preserves empty lines)
      input=("${(f)$(</dev/stdin)}")
    else
      # Bash: use mapfile to read lines (preserves empty lines)
      mapfile -t input < /dev/stdin
    fi
  fi

  local IFS="$delimiter"
  echo "${input[*]}"
}

jwt() {
    if [ -n "$*" ]; then
        input="$*"
    elif ! read -r input && [ -z $input ]; then
        echo "Empty JWT input" >&2
        return 1
    fi
    jq -R 'split(".") | .[1] | @base64d | fromjson' <<<"${input}"
}

urlencode() {
    echo -n "${*:-"$(cat)"}" | jq -Rsr @uri | sed 's/%20/+/g'
}

urldecode() {
    if [ -n "$*" ]; then
        input="$*"
    else
        read -r input
    fi
    echo -n "$input" | python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote_plus(sys.stdin.read()))'
}

catcopy () {
	file_input="" 
	while [ $# -gt 0 ]
	do
		case "$1" in
			(-f | --file) file_input="$2" 
				shift 2 ;;
			(-*) echo "Error: Unknown option $1" >&2
				return 1 ;;
			(*) break ;;
		esac
	done
	if [ -n "$file_input" ]
	then
		if [ -f "$file_input" ]
		then
			input="$(cat "$file_input")" 
		else
			echo "Error: File $file_input" >&2
			return 1
		fi
	elif [ -n "$*" ]
	then
		input="$*" 
	elif [ ! -t 0 ]
	then
		input="$(cat)" 
	else
		echo "Error: No input provided" >&2
		return 1
	fi
	payload="$(jq -n --arg content "$input" '{content: $content}')" 
	curl -X PUT https://0qhtjmwnd3.execute-api.ap-southeast-2.amazonaws.com/prod/clipboard -H "x-api-key:copycat" -s -d "$payload"
}

catpaste () {
	curl https://0qhtjmwnd3.execute-api.ap-southeast-2.amazonaws.com/prod/clipboard -H "x-api-key:copycat" -s | jq -r '.content' | pbcopy
}

