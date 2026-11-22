{ ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting

      set -gx TMUX_TMPDIR $HOME/.local/state
      fish_add_path -g $HOME/.local/bin

      bind up history-prefix-search-backward
      bind down history-prefix-search-forward
    '';

    shellAliases = {
      cat = "bat";
      loc = "tokei";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      username.format = "[karthihegde]($style) in ";
      aws = {
        format = "on [(\\($region\\) )]($style)";
        style = "bold blue";
        symbol = "🅰 ";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };

  programs.eza.enable = true;
  programs.bat.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = false;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "dracarys18";
        email = "me@karthihegde.dev";
      };
      commit.gpgsign = false;
    };
    ignores = [ "**/.claude/settings.local.json" ];
  };

  programs.tmux = {
    enable = true;
    prefix = "C-s";
    keyMode = "vi";
    mouse = true;
    sensibleOnTop = false;
    terminal = "tmux-256color";
    clock24 = true;

    extraConfig = ''
      bind r source-file ~/.config/tmux/tmux.conf
      set -g status-keys vi

      bind h previous-window
      bind l next-window
      bind K confirm kill-window
      bind H split-window -h
      bind V split-window -v
      bind-key n command-prompt 'rename-window "%%"'
      bind-key N command-prompt 'rename-session "%%"'

      set -g extended-keys on
      set -g extended-keys-format csi-u
    '';
  };
}
