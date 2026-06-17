# ``<TAB> trigger
export FZF_COMPLETION_TRIGGER='``'

_fzf_compgen_path() {
  fd --hidden --follow \
  	--exclude ".git" \
  	--exclude "__pycache__" \
  	--exclude "venv" \
  	. "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow \
  	--exclude ".git" \
  	--exclude "__pycache__" \
  	--exclude "venv" \
	. "$1"
}

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' 
  --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'CTRL-Y to copy, CTRL-/ to toggle preview windows'"
  
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}