{
  config,
  pkgs,
  lib,
  inputs,
  writable,
  ...
}:

{
  home.file.".cargo/config.toml".text = ''
    [build]
    target-dir = "${config.home.homeDirectory}/.target"
  '';


  xdg.configFile = {

    "vicinae/settings.json".source = writable "config/vicinae/settings.json";

    "jellyfin-desktop/settings.json".source = writable "config/jellyfin-desktop/settings.json";
    "jellyfin-desktop/mpv/mpv.conf".text = "audio-channels=na-na-fl-fr\n";

  };

}
