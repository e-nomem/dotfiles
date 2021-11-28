#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

install_nix() {
  if ! bin_exists nix; then
    tlib_error_exit "Cannot perform an unattended install of nix!"
  fi
}
task install_nix

install_home_manager() {
  if ! bin_exists home-manager; then
    nix run "$source_dir/nix/.config/nixpkgs#homeConfigurations.eashwar.activationPackage"
  fi
}
task install_home_manager install_nix

update_home_profile() {
  home-manager switch
}
task update_home_profile install_home_manager
