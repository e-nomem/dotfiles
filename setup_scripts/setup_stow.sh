#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

overwrite_stow_targetdir() {
  echo "--target=$HOME/" > "$source_dir/stow/.stowrc"
}
task overwrite_stow_targetdir

stow_stow() {
  stow -t "$HOME" -d "$source_dir" stow
}
task stow_stow install_brewfile overwrite_stow_targetdir
