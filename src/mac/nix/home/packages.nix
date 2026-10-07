# CLI tools from nixpkgs (uji comes from its own flake, in programs/uji)
{ pkgs, inputs, ... }:

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
    # native Spotify client, from its own flake
    inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default

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
