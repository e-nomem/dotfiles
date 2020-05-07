#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

install_gnupg() {
  if ! bin_exists gpgconf; then
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
task stow_gnupg install_gnupg install_pinentry create_gnupg_dir
