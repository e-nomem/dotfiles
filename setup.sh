#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  # This script has been sourced instead of executed
  echo "Please do not source this file!"
  return 1
fi

source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >>/dev/null && pwd )"
# Load up the tasklib and initialize it
# Sourcing the file implicitly initializes the library
. "$source_dir/tasklib.sh"

# Ensure that we trap the EXIT signal to clean up all the tasklib stuff
trap tlib_cleanup EXIT

# Utility function to find an executable in the path
bin_exists() {
  hash "$1" 2>/dev/null
}

## ----- Task Definitions Start Here ----- ##

overwrite_stow_targetdir() {
  echo "--target=$HOME/" > "$source_dir/stow/.stowrc"
}
task overwrite_stow_targetdir

require_osx() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "These task definitions only work with OSX!"
    return 1
  fi
}
task require_osx

install_homebrew() {
  if ! bin_exists brew; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null
  fi
}
task install_homebrew require_osx

update_homebrew() {
  brew update
}
task update_homebrew install_homebrew

install_gnupg() {
  if ! bin_exists gpg; then
    brew install gnupg
  fi
}
task install_gnupg update_homebrew

install_pinentry() {
  if ! bin_exists pinentry-mac; then
    brew install pinentry-mac
  fi
}
task install_pinentry update_homebrew

install_git() {
  if ! bin_exists git; then
    brew install git
  fi
}
task install_git update_homebrew

install_stow() {
  if ! bin_exists stow; then
    brew install stow
  fi
}
task install_stow update_homebrew

install_bins() {
  :
}
task install_bins install_git install_gnupg install_pinentry install_stow

stow_stow() {
  stow -t "$HOME" -d "$source_dir" stow
}
task stow_stow install_stow overwrite_stow_targetdir

stow_git() {
  stow -t "$HOME" -d "$source_dir" git
}
task stow_git stow_stow install_git

create_gnupg_dir() {
  if [[ ! -d "$HOME/.gnupg" ]]; then
    umask 0077
    mkdir "$HOME/.gnupg"
  fi
}
task create_gnupg_dir

stow_gnupg() {
  stow -t "$HOME" -d "$source_dir" gnupg
}
task stow_gnupg stow_stow install_gnupg install_pinentry create_gnupg_dir

create_ssh_dir() {
  if [[ ! -d "$HOME/.ssh" ]]; then
    umask 0077
    mkdir "$HOME/.ssh"
  fi
}
task create_ssh_dir

stow_ssh() {
  stow -t "$HOME" -d "$source_dir" ssh
}
task stow_ssh create_ssh_dir

phony_all() {
  :
}
task phony_all install_bins stow_stow stow_git stow_gnupg stow_ssh

## ----- Task Definitions End Here ----- ##

# Go do the things
run_task phony_all
