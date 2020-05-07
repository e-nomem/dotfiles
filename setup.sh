#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  # This script has been sourced instead of executed
  echo "Please do not source this file!"
  return 1
fi

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >>/dev/null && pwd)"
# Load up the tasklib and initialize it
# Sourcing the file implicitly initializes the library
. "$source_dir/tasklib.sh"

# Ensure that we trap the EXIT signal to clean up all the tasklib stuff
trap tlib_cleanup EXIT

# Utility function to find an executable in the path
bin_exists() {
  hash "$1" 2>/dev/null
}

## ----- Task Definitions Start Here ----- ##

. "$source_dir/setup_scripts/setup_osx.sh"
. "$source_dir/setup_scripts/setup_stow.sh"
. "$source_dir/setup_scripts/setup_git.sh"
. "$source_dir/setup_scripts/setup_gnupg.sh"
. "$source_dir/setup_scripts/setup_ssh.sh"

stow_all() {
  :
}
task stow_all stow_stow stow_gnupg stow_ssh stow_git

## ----- Task Definitions End Here ----- ##

# Go do the things
run_task stow_all
