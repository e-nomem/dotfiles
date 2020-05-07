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

# This variable is no longer required once the tasklib is loaded
unset "source_dir"

# Ensure that we trap the EXIT signal to clean up all the tasklib stuff
trap tlib_cleanup EXIT

# Utility function to find an executable in the path
bin_exists() {
  hash "$1" 2>/dev/null
}

## ----- Task Definitions Start Here ----- ##

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
task install_bins install_git install_gnupg install_stow

## ----- Task Definitions End Here ----- ##

# Go do the things
run_task install_bins
