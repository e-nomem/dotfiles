#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

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

install_brewfile() {
  brew bundle install --file "$source_dir/homebrew/.Brewfile"
}
task install_brewfile update_homebrew

stow_homebrew() {
  stow -t "$HOME" -d "$source_dir" homebrew
}
task stow_homebrew install_brewfile
