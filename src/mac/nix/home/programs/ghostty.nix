{ lib, ... }:

{
  programs.ghostty = {
    enable = true;
    package = null; # the app comes from the Homebrew cask
    # theme and font come from stylix
    settings = {
      # stylix scales sizes by 4/3 for Ghostty; keep the size you had
      font-size = lib.mkForce 25;
      background-opacity = lib.mkForce 0.5;
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
