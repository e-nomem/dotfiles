{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bazelisk
    clusterctl
    direnv
    jq
    mosh
    ripgrep
  ];
}
