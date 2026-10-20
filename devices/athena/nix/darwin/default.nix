# System level (nix-darwin): one file per concern, imported here.
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
  # rust-bin.<channel>.<version> from rust-overlay, instead of rustup
  nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
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

  # The name this Mac answers to: hostname, Bonjour name and the UI name
  networking = {
    hostName = "athena";
    localHostName = "athena";
    computerName = "athena";
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

  # Homebrew is installed and pinned by Nix (flake input), not by the upstream
  # script: /opt/homebrew becomes a managed prefix, and the official taps come
  # from the lockfile. `brew` still installs the casks listed in
  # darwin/homebrew.nix; this only owns brew itself.
  nix-homebrew = {
    enable = true;
    inherit user;
    # the existing /opt/homebrew was installed by the upstream script; move it
    # under nix-homebrew's management instead of asking for a reinstall
    autoMigrate = true;
    # no Rosetta: everything here is aarch64 (no Intel-only casks)
    enableRosetta = false;
    # declarative taps; `mutableTaps = false` means `brew tap` is rejected, so
    # what the flake locks is what brew has
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
