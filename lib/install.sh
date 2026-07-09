#!/usr/bin/env bash

# install.sh — installation helper functions
# Source this file; do not execute directly.

git-install() {
  # Usage: git-install <repo> <home_dir>
  if [ "$#" -ne 2 ]; then
    error "usage: git-install <repo> <home_dir>"
    return 1
  fi

  local repo="$1"
  local home_dir="$2"
  local dry_run="${DRY_RUN:-0}"

  if [ ! -d "$home_dir" ]; then
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] clone $repo → $home_dir"
      if ! GIT_TERMINAL_PROMPT=0 git ls-remote "$repo" > /dev/null 2>&1; then
        error "cannot reach $repo"
        return 1
      fi
    else
      log "cloning $repo → $home_dir"
      git clone "$repo" "$home_dir"
    fi
  else
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] pull $repo -> $home_dir"
      git -C "$home_dir" fetch --dry-run
    else
      log "pulling $repo -> $home_dir "
      git -C "$home_dir" pull
    fi
  fi
}

brew-install() {
  # Usage: brew-install <package>
  if [ "$#" -ne 1 ]; then
    error "usage: brew-install <package>"
    return 1
  fi

  export HOMEBREW_NO_AUTO_UPDATE="1"

  local package="$1"
  local dry_run="${DRY_RUN:-0}"

  if brew list --formula "$package" > /dev/null 2>&1; then
    log "$package is already installed, checking for updates..."
    if brew outdated --quiet "$package" | grep -q .; then
      if [ "$dry_run" = "1" ]; then
        log "[dry-run] upgrade $package"
      else
        log "upgrading $package"
        brew upgrade "$package"
      fi
    else
      log "$package is already up to date"
    fi
  else
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] install $package"
    else
      log "installing $package"
      brew install "$package"
    fi
  fi
}

install-brew() {
  if ! command -v brew > /dev/null 2>&1; then
    log "Homebrew not found, installing..."
    if [ "${DRY_RUN:-0}" = "1" ]; then
      log "[dry-run] install Homebrew"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    brew update
  fi
}

install-python() {
  # Usage: install-python <version>
  if [ "$#" -ne 1 ]; then
    error "usage: install-python <version>"
    return 1
  fi

  local version="$1"
  local dry_run="${DRY_RUN:-0}"

  if ! command -v uv > /dev/null 2>&1; then
    error "uv not found"
    return 1
  fi

  # Match an installed managed Python by major.minor or full version.
  if uv python list --only-installed --managed-python "$version" | grep -q .; then
    log "python $version is already installed (uv managed)"
    return 0
  fi

  if [ "$dry_run" = "1" ]; then
    log "[dry-run] install python $version via uv"
  else
    log "installing python $version via uv"
    uv python install "$version" --default
  fi
}

uv-pip-install() {
  local dry_run="${DRY_RUN:-0}"

  if ! command -v uv > /dev/null 2>&1; then
    error "uv not found"
    return 1
  fi

  if [ "$dry_run" = "1" ]; then
    log "[dry-run] install python packages"
    uv pip install --dry-run "$@"
  else
    log "installing python packages."
    uv pip install "$@"
  fi
}

apt-install() {
  # Usage: apt-install <package>
  if [ "$#" -ne 1 ]; then
    error "usage: apt-install <package>"
    return 1
  fi

  local package="$1"
  local dry_run="${DRY_RUN:-0}"

  if dpkg -s "$package" > /dev/null 2>&1; then
    log "$package is already installed, checking for updates..."
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] apt update && apt upgrade $package"
    else
      log "upgrading $package"
      sudo apt install --only-upgrade "$package"
    fi
  else
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] apt install $package"
    else
      log "installing $package"
      sudo apt install -y "$package"
    fi
  fi
}

snap-install() {
  # Usage: snap-install <package> [extra snap install args...]
  if [ "$#" -lt 1 ]; then
    error "usage: snap-install <package> [args...]"
    return 1
  fi

  local package="$1"; shift
  local dry_run="${DRY_RUN:-0}"

  if snap list "$package" > /dev/null 2>&1; then
    log "$package is already installed, checking for updates..."
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] snap refresh $package"
      snap refresh --list || true
    else
      log "upgrading $package"
      sudo snap refresh "$package" "$@"
    fi
  else
    if [ "$dry_run" = "1" ]; then
      log "[dry-run] snap install $package${*:+ $*}"
      snap info "$package" || true
    else
      log "installing $package"
      sudo snap install "$package" "$@"
    fi
  fi
}

link() {
  local src="$1" dst="$2"
  local dry_run="${DRY_RUN:-0}"

  # dst exists as a real file (not already a symlink) — show what differs
  if [ -f "$dst" ] && [ ! -L "$dst" ]; then
    if ! diff -q "$src" "$dst" > /dev/null 2>&1; then
      log "diff (existing → new): $dst"
      diff --color=auto -u "$dst" "$src" || true
    fi
  fi

  if [ "$dry_run" = "1" ]; then
    log "[dry-run] would link: $src → $dst"
  else
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    log "linked: $src → $dst"
  fi
}

