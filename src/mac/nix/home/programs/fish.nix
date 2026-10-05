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

    # Homebrew is managed by Nix (darwin/homebrew.nix); anything installed by
    # hand is removed on the next switch anyway, so refuse it up front.
    # Read-only commands still work, and Nix calls brew by its full path.
    functions.brew = {
      wraps = "brew";
      description = "Homebrew, minus the commands Nix owns";
      body = ''
        switch "$argv[1]"
            case install reinstall uninstall remove rm upgrade tap untap link unlink pin unpin bundle services trust
                echo "brew $argv[1]: Homebrew is managed by Nix." >&2
                echo "  apps: homebrew.casks in ~/dotfiles/src/mac/nix/darwin/homebrew.nix" >&2
                echo "  CLI tools: home.packages in ~/dotfiles/src/mac/nix/home/packages.nix" >&2
                echo "then run: make switch   (or `command brew ...` to bypass)" >&2
                return 1
        end
        command brew $argv
      '';
    };

    # Same for tools that install globally outside Nix. Building your own
    # local code (`cargo install --path`, `go install ./...`) still works.
    functions.__nix_managed = {
      description = "Explain that a tool belongs in Nix";
      body = ''
        echo "$argv[1]: installs outside Nix. Add the tool to home.packages in" >&2
        echo "  ~/dotfiles/src/mac/nix/home/packages.nix, then run: make switch" >&2
        echo "  (or `command $argv[1] ...` to bypass)" >&2
        return 1
      '';
    };
    functions.cargo = {
      wraps = "cargo";
      description = "cargo, minus installing published crates";
      body = ''
        if test "$argv[1]" = install
            and not contains -- --path $argv
            and not string match -qr -- '^--path=' $argv
            __nix_managed "cargo install"
            return 1
        end
        command cargo $argv
      '';
    };
    functions.go = {
      wraps = "go";
      description = "go, minus installing published tools";
      body = ''
        # `go install pkg@version` fetches a published tool; local packages are fine
        if test "$argv[1]" = install
            and string match -q -- '*@*' $argv[2..-1]
            __nix_managed "go install"
            return 1
        end
        command go $argv
      '';
    };
    functions.npm = {
      wraps = "npm";
      description = "npm, minus global installs";
      body = ''
        if contains -- "$argv[1]" install i add uninstall un remove rm r update up upgrade
            and begin
                contains -- -g $argv
                or contains -- --global $argv
                or contains -- --location=global $argv
            end
            __nix_managed "npm -g"
            return 1
        end
        command npm $argv
      '';
    };

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
