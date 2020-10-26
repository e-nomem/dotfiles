#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

create_ssh_dir() {
  if [[ ! -d "$HOME/.ssh" ]]; then
    # umask ensures proper permissions are set for the ~/.ssh directory
    # It is run in a subshell to ensure that the global umask is not modified
    (umask 0077 && mkdir "$HOME/.ssh")
  fi
}
task create_ssh_dir

stow_ssh() {
  stow -t "$HOME" -d "$source_dir" ssh
}
task stow_ssh install_brewfile create_ssh_dir
