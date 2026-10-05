{
  programs.ghostty = {
    enable = true;
    package = null; # the app comes from the Homebrew cask
    # theme comes from catppuccin/nix (../catppuccin.nix)
    settings = {
      font-family = "Hasklug Nerd Font";
      font-size = 25;
      # mocha's crust (its darkest) instead of base, like Neovim
      background = "11111b";
      background-opacity = 0.5;
      fullscreen = true;
      maximize = true;
      macos-non-native-fullscreen = true;
      macos-auto-secure-input = true;
      macos-secure-input-indication = true;

      shell-integration = "fish";

      window-decoration = false;
      window-vsync = true;
      window-padding-x = 0;
      window-padding-y = 0;
      window-padding-balance = true;
      window-padding-color = "extend";

      keybind = [
        "alt+enter=toggle_fullscreen"
        "ctrl+shift+w=quit"
        "ctrl+shift+r=reload_config"
      ];
    };
  };
}
