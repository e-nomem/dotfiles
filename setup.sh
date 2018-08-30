#!/usr/bin/env bash

if [[ "$BASH_SOURCE" != "$0" ]]; then
  # This script has been sourced instead of executed
  echo "Please do not source this file!"
  return 1
fi

source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >>/dev/null && pwd )"
# Load up the ntasklib and initialize it
# Sourcing the file implicitly initializes the library
. "$source_dir/ntasklib.sh"

# This variable is no longer required once the ntasklib is loaded
unset "source_dir"

# Ensure that we trap the EXIT signal to clean up all the ntasklib stuff
trap ntlib_cleanup EXIT

# Utility function to find an executable in the path
bin_exists() {
  hash "$1" 2>/dev/null
}

## ----- Task Definitions Start Here ----- ##

install_homebrew() {
  if ! bin_exists brew; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null
  fi
}
task install_homebrew

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

install_stow() {
  if ! bin_exists stow; then
    brew install stow
  fi
}
task install_stow update_homebrew

install_git() {
  if ! bin_exists git; then
    brew install git
  fi
}
task install_git update_homebrew

install_mercurial() {
  if ! bin_exists hg; then
    brew install mercurial
  fi
}
task install_mercurial update_homebrew

install_awscli() {
  if ! bin_exists aws; then
    brew install awscli
  fi
}
task install_awscli update_homebrew

install_python() {
  if ! bin_exists python2.7; then
    brew install python@2
  fi
}
task install_python update_homebrew

create_source_dir() {
  mkdir -p "$HOME/src"
}
task create_source_dir

configure_hgrc() {
  if [[ -f "$HOME/.hgrc" ]]; then
    echo "Doing .hgrc stuff"
  else
    echo "Not doing .hgrc stuff"
  fi
}
task configure_hgrc

clone_vanguard() {
  :
}
task clone_vanguard install_mercurial configure_hgrc create_source_dir

install_bins() {
  :
}
task install_bins install_git install_mercurial install_awscli install_python

## ----- Task Definitions End Here ----- ##


# Go do the things
run_task install_bins
