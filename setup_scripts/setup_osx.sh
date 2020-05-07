#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

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
