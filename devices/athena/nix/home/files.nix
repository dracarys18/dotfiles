# Config files linked into ~ and ~/.config. They're read-only copies in the
# Nix store, except the ones an app rewrites itself (`writable`).
{
  config,
  pkgs,
  lib,
  inputs,
  writable,
  ...
}:

{
  # cargo rebuilds into one shared directory instead of a target/ per project.
  # Kept here so `rm -rf ~/.cargo` doesn't take the setting with it.
  home.file.".cargo/config.toml".text = ''
    [build]
    target-dir = "${config.home.homeDirectory}/.target"
  '';


  xdg.configFile = {

    # vicinae saves GUI changes into this file
    "vicinae/settings.json".source = writable "config/vicinae/settings.json";

    # Jellyfin Desktop itself is a hand-installed dev build; it saves window
    # size and server into settings.json, so that file stays writable
    "jellyfin-desktop/settings.json".source = writable "config/jellyfin-desktop/settings.json";
    "jellyfin-desktop/mpv/mpv.conf".text = "audio-channels=na-na-fl-fr\n";

  };

}
