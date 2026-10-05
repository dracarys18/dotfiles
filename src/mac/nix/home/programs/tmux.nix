{ pkgs, inputs, ... }:

let
  # pinned to the commit tpm had installed; nixpkgs' catppuccin is a newer
  # major version with different options
  catppuccin = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "catppuccin";
    version = "0-unstable-pinned";
    src = inputs.tmux-catppuccin;
  };
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-s";
    keyMode = "vi";
    mouse = true;
    # keep tmux's own defaults: home-manager would otherwise add tmux-sensible
    # and switch the terminal to "screen"
    sensibleOnTop = false;
    terminal = "tmux-256color";
    clock24 = true;

    plugins = [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour "mocha"
          set -g @catppuccin_status_modules_right "battery cpu date_time"
          set -g @catppuccin_pane_default_text "#W"
          set -g @catppuccin_window_current_text "#W"
          set -g @catppuccin_date_time_text "%a %b/%d %r"
        '';
      }
      pkgs.tmuxPlugins.battery
      pkgs.tmuxPlugins.cpu
    ];

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

      # true color in Ghostty
      set -sa terminal-features ',xterm-ghostty:RGB'

      set -g extended-keys on
      set -g extended-keys-format csi-u
    '';
  };
}
