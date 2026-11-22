{ config, ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
    };
    brews = [ ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "1password"
      "signal"
      "sony-ps-remote-play"
      "telegram"
      "vesktop"
      "obs"
      "maccy"
      "vicinae"
      "chatterino"
      "obsidian"
      "kde-connect"
      "ghostty"
    ];
    masApps = {
      Developer = 640199958;
      TestFlight = 899247664;
    };
  };
}
