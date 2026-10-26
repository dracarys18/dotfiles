# CLI tools for the everyday shell. Deliberately not the Mac's list: no Rust or
# Go toolchain, no zig/opam/jdk, nothing GUI. A server needs the small stuff.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # search and text
    ripgrep
    fd
    jq
    yq
    glow
    tokei

    # inspection
    btop
    ncdu
    tree
    fastfetch
    file
    less

    # transfer and archives
    rsync
    unzip
    zip
    curl
    wget
    openssl

    # git and forge
    gh
    git
    delta
  ];
}
