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