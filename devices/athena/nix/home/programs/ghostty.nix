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
