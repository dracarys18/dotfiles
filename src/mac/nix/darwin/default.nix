# System level (nix-darwin): one file per concern, imported here.
{ pkgs, ... }:

let
  user = "karthihegde";
in
{
  imports = [
    ./shell.nix
    ./homebrew.nix
    ./defaults.nix
    ./debloat.nix
    ./yabai.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = user;

  users.users.${user}.home = "/Users/${user}";

  fonts.packages = [ pkgs.nerd-fonts.hasklug ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
}
