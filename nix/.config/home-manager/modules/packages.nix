{ pkgs, ... }:
{
  home.packages = with pkgs; [
    _1password-cli
    age-plugin-yubikey
    apko
    beancount
    fish
    fnm
    go
    gomplate
    jq
    melange
    mosh
    nushell
    pipenv
    pre-commit
    pstree
    rage
    ripgrep
    sccache
    socat
#    step-cli
    yt-dlp
    yubikey-agent
    yubikey-manager
    zig
  ];
}
