# Config files linked into ~ and ~/.config. They're read-only copies in the
# Nix store, except the ones an app rewrites itself (`writable`).
{
  pkgs,
  lib,
  inputs,
  writable,
  ...
}:

{
  xdg.configFile = {

    "uji" = {
      source = ../../../../config/uji;
      recursive = true;
    };
    # vicinae saves GUI changes into this file
    "vicinae/settings.json".source = writable "config/vicinae/settings.json";

    # Jellyfin Desktop itself is a hand-installed dev build; it saves window
    # size and server into settings.json, so that file stays writable
    "jellyfin-desktop/settings.json".source = writable "config/jellyfin-desktop/settings.json";
    "jellyfin-desktop/mpv/mpv.conf".source = ../../../../config/jellyfin-desktop/mpv/mpv.conf;

    "1Password/ssh/agent.toml".source = ../../../../config/1Password/ssh/agent.toml;
  };

}
