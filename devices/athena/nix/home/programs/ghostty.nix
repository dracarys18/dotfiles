{ pkgs, ... }:

{
  # nixpkgs' source build of ghostty is Linux-only; ghostty-bin is the macOS
  # bundle, and setting package here both installs it and links it into
  # ~/Applications/Home Manager Apps (see darwin/defaults.nix for the Dock entry)
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    # no vim here (Neovim is nixvim), so don't pull ghostty's vim plugin in
    installVimSyntax = false;
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
