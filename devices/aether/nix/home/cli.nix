# Shell and terminal tools, matching the Mac's programs/*.nix. Difference: no
# Homebrew paths, no launchctl aliases, no `pdf = mupdf-gl`, and commit signing
# is off because that key lives in 1Password on the Mac.
{ ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting

      # tmux keeps its server socket in $TMUX_TMPDIR; the default is /tmp, which
      # gets cleared often enough to strand running sessions
      set -gx TMUX_TMPDIR $HOME/.local/state
      fish_add_path -g $HOME/.local/bin

      # up/down search history by the prefix already typed
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
    # `cd` jumps by frecency, like the old `alias cd=z`
    options = [ "--cmd cd" ];
  };

  # also adds ll, la, lt and lla aliases next to ls
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
      # no gpg.ssh.program here: that is 1Password's op-ssh-sign on the Mac
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

    # no catppuccin plugin: the Mac pins a specific revision because the
    # current one breaks the cpu/battery modules, and those mean nothing on a
    # headless server anyway
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
