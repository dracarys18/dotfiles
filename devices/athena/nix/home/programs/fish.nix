{ inputs, ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting

      set -gx TMUX_TMPDIR $HOME/.local/state

      fish_add_path -g --append /opt/homebrew/bin
      fish_add_path -g --append /opt/homebrew/sbin
      fish_add_path -g $HOME/.local/bin

      if test -r $HOME/.opam/opam-init/init.fish
          source $HOME/.opam/opam-init/init.fish >/dev/null 2>&1
      end

      bind up history-prefix-search-backward
      bind down history-prefix-search-forward

      for secret in litellm/api_key:LITELLM_API_KEY litellm/base_url:LITELLM_BASE_URL
          set -l parts (string split : $secret)
          if test -r /run/secrets/$parts[1]
              set -gx $parts[2] (cat /run/secrets/$parts[1])
          end
      end
    '';

    functions.brew = {
      wraps = "brew";
      description = "Homebrew, minus the commands Nix owns";
      body = ''
        switch "$argv[1]"
            case install reinstall uninstall remove rm upgrade tap untap link unlink pin unpin bundle services trust
                echo "brew $argv[1]: Homebrew is managed by Nix." >&2
                echo "  apps: homebrew.casks in ~/dotfiles/devices/athena/nix/darwin/homebrew.nix" >&2
                echo "  CLI tools: home.packages in ~/dotfiles/devices/athena/nix/home/packages.nix" >&2
                echo "then run: make switch   (or `command brew ...` to bypass)" >&2
                return 1
        end
        command brew $argv
      '';
    };

    functions.__nix_managed = {
      description = "Explain that a tool belongs in Nix";
      body = ''
        echo "$argv[1]: installs outside Nix. Add the tool to home.packages in" >&2
        echo "  ~/dotfiles/devices/athena/nix/home/packages.nix, then run: make switch" >&2
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

    functions.pip3 = {
      wraps = "pip3";
      description = "pip3, redirected to uv";
      body = ''
        if contains -- "$argv[1]" install i add download
            echo "pip3: that pip belongs to Xcode's Python 3.9. Use uv:" >&2
            echo "  uv add <pkg>          project dependency" >&2
            echo "  uv pip install <pkg>  inside a uv venv" >&2
            echo "  uv tool install <pkg> CLI tools" >&2
            echo "  (or `command pip3 ...` to bypass)" >&2
            return 1
        end
        command pip3 $argv
      '';
    };

    functions.vpn = {
      description = "Turn the tailscale exit node on or off";
      body = ''
        set -l node sg-sin-wg-001.mullvad.ts.net
        if test (count $argv) -ge 2
            set node $argv[2]
        end

        switch "$argv[1]"
            case on
                tailscale set --exit-node=$node
                for attempt in 1 2 3
                    if curl -fsS -m 5 -o /dev/null https://ifconfig.me
                        echo "vpn: on, via $node"
                        return 0
                    end
                    sleep 2
                end
                tailscale set --exit-node=
                echo "vpn: $node passes no traffic, turned back off" >&2
                return 1
            case off
                tailscale set --exit-node=
                echo "vpn: off"
            case '*'
                echo "usage: vpn on [node] | vpn off" >&2
                return 1
        end
      '';
    };

    shellAliases = {
      cat = "bat";
      tf = "terraform";
      pdf = "mupdf-gl -I";
      loc = "tokei";
      sshat = "ssh aether";
      yabai-restart = ''launchctl kickstart -k gui/(id -u)/org.nixos.yabai'';
      skhd-restart = ''launchctl kickstart -k gui/(id -u)/org.nixos.skhd'';
    };
  };

  programs.man.generateCaches = false;

  home.sessionVariables = {
    ANTHROPIC_SMALL_FAST_MODEL = "claude-sonnet-4-6";
  };

  xdg.configFile."fish/conf.d/kubectl_aliases.fish".source =
    "${inputs.kubectl-aliases}/.kubectl_aliases.fish";
}
