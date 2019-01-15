#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  # This script has been sourced instead of executed
  echo "Please do not source this file!"
  return 1
fi

source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >>/dev/null && pwd )"
# Load up the ntasklib and initialize it
# Sourcing the file implicitly initializes the library
# . "$source_dir/ntasklib.sh"
. "$source_dir/tasklib.sh"

# This variable is no longer required once the ntasklib is loaded
unset "source_dir"

# Ensure that we trap the EXIT signal to clean up all the ntasklib stuff
# trap ntlib_cleanup EXIT
trap tlib_cleanup EXIT

# Utility function to find an executable in the path
bin_exists() {
  hash "$1" 2>/dev/null
}

## ----- Task Definitions Start Here ----- ##

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

install_gnupg() {
  if ! bin_exists gpg; then
    brew install gnupg
  fi
}
task install_gnupg update_homebrew

install_stow() {
  if ! bin_exists stow; then
    brew install stow
  fi
}
task install_stow update_homebrew

install_git() {
  if ! bin_exists git; then
    brew install git
  fi
}
task install_git update_homebrew

install_mercurial() {
  if ! bin_exists hg; then
    brew install mercurial
  fi
}
task install_mercurial update_homebrew

install_awscli() {
  if ! bin_exists aws; then
    brew install awscli
  fi
}
task install_awscli update_homebrew

install_pyenv() {
  if ! bin_exists pyenv; then
    brew install pyenv
  fi

  source /dev/stdin <<<"$(pyenv init -)"
}
task install_pyenv update_homebrew

install_pyenv_virtualenv() {
  if ! bin_exists pyenv-virtualenv-init; then
    brew install pyenv-virtualenv
  fi
  source /dev/stdin <<<"$(pyenv virtualenv-init -)"
}
task install_pyenv_virtualenv install_pyenv

install_python27() {
  pyenv versions --bare | grep -q '^2\.7\.15$'
  if [[ "$?" != 0 ]]; then
    pyenv install 2.7.15
  fi
}
task install_python27 install_pyenv

create_vanguard_venv() {
  pyenv virtualenvs --bare | grep -q '^vanenv$'
  if [[ "$?" != 0 ]]; then
    pyenv virtualenv 2.7.15 vanenv
  fi
}
task create_vanguard_venv install_pyenv_virtualenv install_python27

set_local_venv() {
  pushd "$HOME/src/vanguard"
  if ! pyenv local > /dev/null 2>&1; then
    pyenv local vanenv
  fi
  popd
}
task set_local_venv create_vanguard_venv clone_vanguard

create_source_dir() {
  mkdir -p "$HOME/src"
}
task create_source_dir

configure_hgrc_pull_fingerprint() {
  local expected actual hg_server
  hg_server=$1
  expected="562BF2679306018A2BD8F81868541928C3D5F5C42B96CEC6956816909DD874B1"
  actual="$(echo -n | openssl s_client -servername "$hg_server" -connect "${hg_server}:443" 2>/dev/null | openssl x509 -fingerprint -noout -sha256 | cut -d'=' -f2 | tr -d ':')"

  [[ "$expected" == "$actual" ]] && echo "$actual"
}

configure_hgrc_generate_hgrc() {
  local srvsection
  srvsection=$(echo "$1" | tr '.' '-')
  cat <<EOF
[ui]
username = $5 <$4@apptio.com>

[auth]
$srvsection.prefix = $1$2
$srvsection.username = $4
$srvsection.schemes = https

[hostsecurity]
disabletls10warning = true
$1:minimumprotocol = tls1.0
$1:fingerprints = sha256:$3

[extensions]
mercurial_keyring =

EOF
}

configure_hgrc() {
  if [[ -f "$HOME/.hgrc" ]]; then
    echo "$HOME/.hgrc already exists... doing nothing"
  else
    local username fullname fingerprint hg_server hg_server_path
    hg_server=hg.dapt.to
    hg_server_path=/hg
    username=$(who am i | cut -d' ' -f1)
    fullname=$(dscacheutil -q user -a name "$username" | grep gecos | cut -d' ' -f2-)
    fingerprint=$(configure_hgrc_pull_fingerprint "$hg_server")

    if [[ -z "$fingerprint" ]]; then
      echo "Failed to pull or verify server tls fingerprint"
      return 1
    fi

    configure_hgrc_generate_hgrc "$hg_server" "$hg_server_path" "$fingerprint" "$username" "$fullname" > "$HOME/.hgrc"
  fi
}
task configure_hgrc

clone_vanguard() {
  :
}
task clone_vanguard install_mercurial configure_hgrc create_source_dir

install_bins() {
  :
}
task install_bins install_git install_mercurial

## ----- Task Definitions End Here ----- ##


# Go do the things
run_task install_bins
