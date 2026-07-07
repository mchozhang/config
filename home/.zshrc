#!/usr/bin/env zsh

# config bootstrap
export CONFIG_HOME="$HOME/opt/config"
source "${CONFIG_HOME}/lib/bootstrap.sh"

alias ls="ls --color=auto -G -a"
alias ll="ls -alFh"

# aws scrape
aws_scrape_path="$HOME/.aws/cli/aws-cli-completion"
fpath=("$aws_scrape_path/zsh" $fpath)

# local custom functions
for i in "$HOME"/.local/lib/*; do
	source "$i"
done

# zoxide
eval "$(zoxide init zsh)"

# vim
alias v="vim"

# bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="Catppuccin Macchiato"
alias cat="bat --paging=never --plain"
alias less="bat -p"

# aws auto complete
complete -C '/usr/local/bin/aws_completer' aws

# go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# IDE
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
alias idea="open -a 'IntelliJ IDEA'"
alias pycharm="open -a 'Pycharm'"
alias webstorm="open -a webstorm"
alias goland="open -a goland"
alias rider="open -a rider"

# gnu-sed
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

# gnu coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"


# curl
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# openssl
export PATH="/opt/homebrew/opt/openssl/bin:$PATH"

# n
export N_PREFIX=$HOME/.n
export PATH="$N_PREFIX/bin:$PATH"

# grep 
alias grep="ggrep --color=auto"

# gtime
alias time="gtime -p"

# gxargs
alias xargs="gxargs"

# gnu-getopt
export PATH="/opt/homebrew/opt/gnu-getopt/bin:$PATH"

# gpg
export GPG_TTY="$(tty)"

# tree
alias tree="tree -C"

# dotnet
export PATH="$PATH:$HOME/.dotnet/tools" 

# terraform
complete -o nospace -C /usr/local/bin/terraform terraform

# csi
export PATH="$PATH:$HOME/environment/csi/bin"

# uncomment to test launch time
# zprof
