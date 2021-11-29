{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bazelisk
    clusterctl
    deno
    direnv
    jq
    kind
    kubectl
    kubernetes-helm
    mosh
    pipenv
    pre-commit
    pstree
    ripgrep
    socat
    step-cli
  ];
}
