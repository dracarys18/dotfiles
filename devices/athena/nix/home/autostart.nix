# Autostart for the apps that live in ~/Applications/Home Manager Apps.
#
# A macOS login item records the path it was given *resolved*, so it ends up
# pointing into the store and dies on the next update (the same trap as the
# Dock). Declaring the launch agents here keeps the stable home-manager path:
# launchd resolves it at login time, so it always follows the current
# generation.
{ config, ... }:

let
  apps = "${config.home.homeDirectory}/Applications/Home Manager Apps";
  # `open -a` rather than the binary, so the app starts through LaunchServices
  # like a normal login item would
  open = "/usr/bin/open";
  agent = name: {
    enable = true;
    config = {
      ProgramArguments = [
        open
        "-a"
        "${apps}/${name}.app"
      ];
      RunAtLoad = true;
    };
  };
in
{
  launchd.agents = {
    maccy = agent "Maccy";
    vicinae = agent "Vicinae";
  };
}
