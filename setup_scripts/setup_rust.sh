#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

install_rustup() {
  if ! bin_exists brew; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path --default-toolchain none -y < /dev/null
  fi
}
task install_rustup

update_rustup() {
  rustup self update
}
task update_rustup install_rustup

# This function generates the task to install specific crates
generate_crate_install() {
	local channel crate tasks taskName safe_channel
	channel="$1"
	safe_channel="${channel//[-.]/_}"
	shift

	tasks=()
	for crate in "$@"; do
	    taskName="crate_${safe_channel}_${crate//-/_}"
		tlib_generate_task "$taskName" "update_rust_$safe_channel" <<FUNC
cargo +$channel install $crate
FUNC
		tasks+=("$taskName")
	done
	phony "update_crates_$safe_channel" "${tasks[@]}"
}

# install_rust is a function that actually generates a set of tasks
# to set up a default profile for all the rust channels we want
genrate_install_rust() {
	local channel tasks safe_channel
	tasks=()
	for channel in "$@"; do
		safe_channel="${channel//[-.]/_}"
		tlib_generate_task "update_rust_$safe_channel" update_rustup <<FUNC
rustup update $channel --no-self-update
FUNC
		generate_crate_install "$channel" cargo-audit cargo-edit cargo-feature
		phony "rust_$safe_channel" "update_rust_$safe_channel" "update_crates_$safe_channel"
		tasks+=("rust_$safe_channel")
	done
	phony rust_all "${tasks[@]}"
}

genrate_install_rust stable
