# User level: CLI tools and config files.
#
# Config files are copied into the Nix store and linked from there, so they are
# read-only: edit them in ~/dotfiles/config, then `darwin-rebuild switch`.
# The exception is files an app rewrites itself, which link straight to the repo.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  writable = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.username = "karthihegde";
  home.homeDirectory = "/Users/karthihegde";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # shell and terminal
    starship
    tmux
    zoxide
    fzf
    eza
    bat
    ripgrep
    jq
    direnv
    fastfetch
    tokei
    witr
    glow

    # editors and languages
    neovim
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
    cloudflared

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

  xdg.configFile = {
    "nvim" = {
      # vim.pack rewrites its lockfile, so that one file stays writable
      source = lib.cleanSourceWith {
        src = ./config/nvim;
        filter = path: _: baseNameOf path != "nvim-pack-lock.json";
      };
      recursive = true;
    };
    "nvim/nvim-pack-lock.json".source = writable "config/nvim/nvim-pack-lock.json";

    "fish/config.fish".source = ./config/fish/config.fish;
    "fish/conf.d" = {
      source = ./config/fish/conf.d;
      recursive = true;
    };
    # starship's init script hardcodes the binary's path, so build it from
    # this exact starship instead of keeping a cached copy in the repo
    "fish/conf.d/starship_init.fish".source = pkgs.runCommand "starship_init.fish" { } ''
      ${pkgs.starship}/bin/starship init fish --print-full-init > $out
    '';
    "starship.toml".source = ./config/starship.toml;

    "ghostty" = {
      source = ./config/ghostty;
      recursive = true;
    };
    "wezterm" = {
      source = ./config/wezterm;
      recursive = true;
    };
    "uji" = {
      source = ./config/uji;
      recursive = true;
    };
    # vicinae saves GUI changes into this file
    "vicinae/settings.json".source = writable "config/vicinae/settings.json";

    # Shared git settings. `git config --global` writes to ~/.gitconfig, which
    # stays a plain local file for machine-specific or tool-written settings.
    "git/config".source = ./config/git/config;
    "git/ignore".source = ./config/git/ignore;

    "1Password/ssh/agent.toml".source = ./config/1Password/ssh/agent.toml;
  };

  home.file = {
    ".tmux.conf".source = ./config/tmux.conf;
    ".tmux/plugins/tpm".source = inputs.tpm;
    ".yabairc".source = ./config/yabai/yabairc;
    ".skhdrc".source = ./config/yabai/skhdrc;
  };

  # Firefox's profile folder has a random name, so it can't be a home.file
  # target. Link firefox/ into the default-release profile once it exists.
  home.activation.firefoxProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    firefoxDir="$HOME/Library/Application Support/Firefox"
    profile=$(${pkgs.gawk}/bin/awk -F= '
      /^\[/ { if (name == "default-release") print path; name = ""; path = "" }
      $1 == "Name" { name = $2 }
      $1 == "Path" { path = $2 }
      END { if (name == "default-release") print path }
    ' "$firefoxDir/profiles.ini" 2>/dev/null | head -1 || true)

    linkFirefox() {
      if [ -e "$2" ] && [ ! -L "$2" ]; then
        run mv "$2" "$2.before-nix"
      fi
      run ln -sfn "$1" "$2"
    }

    if [ -n "$profile" ]; then
      linkFirefox ${./firefox/chrome} "$firefoxDir/$profile/chrome"
      linkFirefox ${./firefox/user.js} "$firefoxDir/$profile/user.js"
    fi
  '';
}
