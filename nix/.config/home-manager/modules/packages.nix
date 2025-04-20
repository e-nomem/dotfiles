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
    jujutsu
    jq
    melange
    mosh
    nushell
    pre-commit
    pstree
    ripgrep
    sccache
    socat
    uv
    yt-dlp
    yubikey-manager
    zig
  ];
}
