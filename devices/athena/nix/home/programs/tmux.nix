{ pkgs, inputs, ... }:

let
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
    sensibleOnTop = false;
    terminal = "tmux-256color";
    clock24 = true;

    plugins = [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
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

      set -sa terminal-features ',xterm-ghostty:RGB'

      set -g allow-passthrough on

      set -g extended-keys on
      set -g extended-keys-format csi-u
    '';
  };
}
