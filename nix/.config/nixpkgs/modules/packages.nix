{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bazelisk
    beancount
    clusterctl
    # deno
    direnv
    fish
    fnm
    hub
    jq
    kind
    kubectl
    kubernetes-helm
    mosh
    nushell
    pipenv
    pre-commit
    protobuf
    pstree
    ripgrep
    socat
    step-cli
  ];
}
