#!/usr/bin/env zsh

# config bootstrap
export CONFIG_HOME="$HOME/opt/config"
source "${CONFIG_HOME}/lib/bootstrap.sh"

# local custom functions
for i in "$HOME"/.local/lib/*; do
	source "$i"
done

# vim
alias v="vim"

# go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# uncomment to test launch time
# zprof
