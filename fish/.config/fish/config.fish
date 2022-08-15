if status --is-interactive
    set -x SSH_AUTH_SOCK (gpgconf --list-dir agent-ssh-socket)
    fish_add_path -p $HOME/bin /usr/local/sbin
    fish_add_path -a $HOME/.cargo/bin $HOME/.krew/bin $HOME/Library/Android/sdk/tools $HOME/Library/Android/sdk/platform-tools
    set -x LSCOLORS gxfxcxdxbxegedabagacad
    source $HOME/google-cloud-sdk/path.fish.inc
end
