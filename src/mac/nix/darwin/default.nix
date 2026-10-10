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
    ./intelligence.nix
    ./yabai.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  # signal-desktop, spotify and _1password-cli are unfree
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = 6;
  system.primaryUser = user;

  users.users.${user}.home = "/Users/${user}";

  fonts.packages = [ pkgs.nerd-fonts.hasklug ];

  # The Tailscale CLI and its daemon, instead of the menu-bar app. All DNS goes
  # through Tailscale: the admin console's DNS page has a nameserver and
  # "Override local DNS" on, and the forwarder answers (`tailscale dns query`).
  services.tailscale = {
    enable = true;
    overrideLocalDns = true;
  };

  # DNS override applies to the services listed here; with the list empty
  # nix-darwin warns and changes nothing
  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
    "AX88179A"
    "Thunderbolt Bridge"
    "iPhone USB"
  ];

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
