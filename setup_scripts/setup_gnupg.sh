#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

create_gnupg_dir() {
  if [[ ! -d "$HOME/.gnupg" ]]; then
    # umask ensures proper permissions are set for the ~/.gnupg directory
    # It is run in a subshell to ensure that the global umask is not modified
    (umask 0077 && mkdir "$HOME/.gnupg")
  fi
}
task create_gnupg_dir

stow_gnupg() {
  stow -t "$HOME" -d "$source_dir" gnupg
}
task stow_gnupg install_brewfile create_gnupg_dir
