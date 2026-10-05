{ inputs, ... }:

{
  programs.fish = {
    enable = true;

    # only in interactive shells, like the old config.fish
    interactiveShellInit = ''
      set -g fish_greeting
      fish_config theme choose catppuccin-mocha

      # Homebrew only holds GUI apps and a few macOS tools; Nix paths come first
      fish_add_path -g --append /opt/homebrew/bin
      fish_add_path -g --append /opt/homebrew/sbin
      fish_add_path -g $HOME/.cargo/bin
      fish_add_path -g $HOME/.local/bin

      if test -r $HOME/.opam/opam-init/init.fish
          source $HOME/.opam/opam-init/init.fish >/dev/null 2>&1
      end

      # up/down search history by the prefix already typed
      bind up history-prefix-search-backward
      bind down history-prefix-search-forward
    '';

    shellAliases = {
      cat = "bat";
      tf = "terraform";
      pdf = "mupdf-gl -I";
      loc = "tokei";
      sshat = ''ssh arch -t "fish"'';
    };
  };

  # fish's module asks for man-page caches, but on macOS the system's own man
  # is used (programs.man.package is null), so they'd do nothing but warn
  programs.man.generateCaches = false;

  home.sessionVariables = {
    ANTHROPIC_SMALL_FAST_MODEL = "claude-sonnet-4-6";
  };

  # kubectl abbreviations (`k`, `kgp`…), pinned from ahmetb/kubectl-aliases
  xdg.configFile."fish/conf.d/kubectl_aliases.fish".source =
    "${inputs.kubectl-aliases}/.kubectl_aliases.fish";
}
