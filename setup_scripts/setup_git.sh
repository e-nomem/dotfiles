#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

install_git() {
  if ! bin_exists git; then
    brew install git
  fi
}
task install_git update_homebrew

stow_git() {
  stow -t "$HOME" -d "$source_dir" git
}
task stow_git install_git
