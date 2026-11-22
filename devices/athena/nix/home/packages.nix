{
  inputs,
  pkgs,
  ...
}:

let
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
    ripgrep
    jq
    fastfetch
    tokei
    witr
    glow
    vhs

    inputs.sonora.packages.${pkgs.stdenv.hostPlatform.system}.default

    rust
    (pkgs.callPackage ../pkgs/hades.nix { src = inputs.hades; })
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

    automake
    libtool
    cmake
    pkgconf
    just

    colima
    docker-client
    docker-compose
    docker-credential-helpers
    kubectl

    android-tools

    gh
    _1password-cli
    sops
    age
    gnupg
    gnused
    wget
    inetutils
    croc
    cloudflared
    mupdf
    ffmpeg
    mpv
    xcodes

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
