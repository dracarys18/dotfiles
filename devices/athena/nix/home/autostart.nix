{ config, ... }:

let
  hmApps = "${config.home.homeDirectory}/Applications/Home Manager Apps";
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
