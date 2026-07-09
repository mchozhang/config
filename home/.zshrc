#!/usr/bin/env zsh

# config bootstrap
export CONFIG_HOME="$HOME/opt/config"
source "${CONFIG_HOME}/lib/bootstrap.sh"

# aws scrape
aws_scrape_path="$HOME/.aws/cli/aws-cli-completion"
fpath=("$aws_scrape_path/zsh" $fpath)

# local custom functions
for i in "$HOME"/.local/lib/*; do
	source "$i"
done

# vim
alias v="vim"

# go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# tree
alias tree="tree -C"

# dotnet
export PATH="$PATH:$HOME/.dotnet/tools" 

# terraform
complete -o nospace -C /usr/local/bin/terraform terraform

# uncomment to test launch time
# zprof
