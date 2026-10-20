# CLI tools from nixpkgs (uji comes from its own flake, in programs/uji)
{
  inputs,
  pkgs,
  ...
}:

let
  # the toolchain uji's rust-toolchain.toml pins, with the components a dev
  # needs; replaces rustup and everything in ~/.cargo/bin
  rust = pkgs.rust-bin.stable."1.99.0".default.override {
    extensions = [
      "clippy"
      "rustfmt"
      "rust-analyzer"
    ];
  };
in
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
    rust
    # the local hades workspace, built in the store (../pkgs/hades.nix)
    (pkgs.callPackage ../pkgs/hades.nix { src = inputs.hades; })
    go
    nodejs
    bun
    # no python3 from nixpkgs on purpose: uv owns the interpreter and
    # `uv python install 3.13 --default` shims ~/.local/bin/python3 at it
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

    android-tools # adb and fastboot
    # every GUI app comes from Homebrew now (darwin/homebrew.nix): TCC
    # permissions are granted per code identity, and a store-path bundle is a
    # new identity on every update, so screen recording / camera / accessibility
    # died each time. mupdf and mpv stay here: brew's mupdf formula installs
    # only mutool/mudraw (no viewer), and mpv's formula can't build against the
    # pinned brew (see darwin/homebrew.nix).
    # signal-desktop stays a cask for now: nixpkgs ships 8.29.0, which can't
    # read a database migrated by 8.30.0 (schema 1830 vs its 1800). Its own
    # updater keeps the cask current; move it back to Nix once nixpkgs >= 8.30
    # jellyfin-desktop stays a hand build: nixpkgs' qtwebengine fails to
    # compile on aarch64-darwin (Chromium's abseil vs libc++ headers)

    # network and misc
    gh
    _1password-cli
    sops
    age
    gnupg
    gnused
    wget
    inetutils
    croc
    # mupdf keeps its app bundle only in nixpkgs: the brew formula installs
    # just mutool/mudraw, so the viewer would be lost (see darwin/homebrew.nix)
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
