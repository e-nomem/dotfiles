{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bazelisk
    clusterctl
    direnv
    jq
    kind
    kubectl
    kubernetes-helm
    mosh
    ripgrep
  ];
}
