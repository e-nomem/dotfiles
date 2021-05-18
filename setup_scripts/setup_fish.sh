#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

create_fish_dir() {
  if [[ ! -d "$HOME/.config/fish" ]]; then
	mkdir "$HOME/.config"
    # umask ensures proper permissions are set for the ~/.ssh directory
    # It is run in a subshell to ensure that the global umask is not modified
    (umask 0077 && mkdir "$HOME/.config/fish")
  fi
}
task create_fish_dir

stow_fish() {
  stow -t "$HOME" -d "$source_dir" fish
}
task stow_fish install_brewfile create_fish_dir
