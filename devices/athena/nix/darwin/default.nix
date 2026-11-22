{ inputs, pkgs, ... }:

let
  user = "karthihegde";
in
{
  imports = [
    ./shell.nix
    ./homebrew.nix
    ./defaults.nix
    ./debloat.nix
    ./intelligence.nix
    ./secrets.nix
    ./yabai.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = 6;
  system.primaryUser = user;

  users.users.${user}.home = "/Users/${user}";

  fonts.packages = [ pkgs.nerd-fonts.hasklug ];

  services.tailscale = {
    enable = true;
    overrideLocalDns = true;
  };

  networking = {
    hostName = "athena";
    localHostName = "athena";
    computerName = "athena";
  };

  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
    "AX88179A"
    "Thunderbolt Bridge"
    "iPhone USB"
  ];

  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
    enableRosetta = false;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

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
