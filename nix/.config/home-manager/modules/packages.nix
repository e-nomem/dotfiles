{ pkgs, ... }:
{
  home.packages = with pkgs; [
    _1password-cli
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
    pre-commit
    pstree
    ripgrep
    sccache
    socat
    yt-dlp
    yubikey-manager
    zig
  ];
}
