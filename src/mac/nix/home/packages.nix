# CLI tools from nixpkgs (uji comes from its own flake, in programs/uji)
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # shell and terminal (starship, tmux, zoxide, fzf, eza, bat and direnv come
    # from their modules in programs/)
    ripgrep
    jq
    fastfetch
    tokei
    witr
    glow
    vhs

    # editors and languages (neovim comes from programs.nixvim)
    go
    nodejs
    bun
    uv
    zig
    opam
    jdk
    llvm
    clang-tools
    nasm
    lua54Packages.luacheck
    stylua
    ast-grep
    cargo-nextest
    diesel-cli
    protobuf
    buf
    platformio
    typst

    # build tools
    automake
    libtool
    cmake
    pkgconf
    just

    # containers and cloud
    colima
    docker-client
    docker-compose
    docker-credential-helpers
    kubectl

    # apps
    chatterino2

    # network and misc
    gh
    gnupg
    gnused
    wget
    inetutils
    croc
    mupdf
    ffmpeg
    mpv
    xcodes

    # go tools
    gopls
    gotools
    delve
    gofumpt
    golangci-lint
    golines
    gomodifytags
    gotests
    gotestsum
    govulncheck
    impl
    mockgen
    richgo
    ginkgo
    reftools
    iferr

    # rust and web tools
    cargo-bloat
    cargo-generate
    cargo-wipe
    mdbook
    tree-sitter
    typos
    wasm-pack
    newman
  ];
}
