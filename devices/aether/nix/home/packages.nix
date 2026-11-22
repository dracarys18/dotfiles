{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq
    glow
    tokei

    btop
    ncdu
    tree
    fastfetch
    file
    less

    rsync
    unzip
    zip
    curl
    wget
    openssl

    gh
    git
    delta
  ];
}
