# Ghostty is a cask (darwin/homebrew.nix): upstream's signed bundle in
# /Applications, updated by brew. Nix only writes the config file, so there is
# no wrapper and no store-path bundle. catppuccin.ghostty is left off in
# ../catppuccin.nix for the same reason — it themes programs.ghostty, which is
# a Nix package — so the theme is picked by name from Ghostty's own bundled
# themes, and the mocha crust background is set explicitly.
{ ... }:

{
  xdg.configFile."ghostty/config".text = ''
    font-family = Hasklug Nerd Font
    font-size = 25
    theme = Catppuccin Mocha
    background = 11111b
    background-opacity = 0.5
    fullscreen = true
    maximize = true
    macos-non-native-fullscreen = true
    macos-auto-secure-input = true
    macos-secure-input-indication = true

    shell-integration = fish

    window-decoration = false
    window-vsync = true
    window-padding-x = 0
    window-padding-y = 0
    window-padding-balance = true
    window-padding-color = extend

    keybind = alt+enter=toggle_fullscreen
    keybind = ctrl+shift+w=quit
    keybind = ctrl+shift+r=reload_config
  '';
}
