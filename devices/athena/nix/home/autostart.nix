# Autostart for the apps that live in ~/Applications/Home Manager Apps, plus
# the two cask apps (Maccy, Vicinae) that moved out because their Accessibility
# permission died with every store-path update.
#
# A macOS login item records the path it was given *resolved*, so it ends up
# pointing into the store and dies on the next update (the same trap as the
# Dock). Declaring the launch agents here keeps the stable path: launchd
# resolves it at login time, so it always follows the current app.
{ config, ... }:

let
  hmApps = "${config.home.homeDirectory}/Applications/Home Manager Apps";
  # `open -a` rather than the binary, so the app starts through LaunchServices
  # like a normal login item would
  open = "/usr/bin/open";
  agent = dir: name: {
    enable = true;
    config = {
      ProgramArguments = [
        open
        "-a"
        "${dir}/${name}.app"
      ];
      RunAtLoad = true;
    };
  };
in
{
  launchd.agents = {
    maccy = agent "/Applications" "Maccy";
    vicinae = agent "/Applications" "Vicinae";
  };
}
