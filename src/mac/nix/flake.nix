{
  description = "karthihegde's Mac: nix-darwin for the system, home-manager for the user";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # catppuccin for tmux, pinned to the version the config is written for
    tmux-catppuccin = {
      url = "github:catppuccin/tmux/1612a23174a6771ac466312eb156f83b8b89d907";
      flake = false;
    };
    # TODO(macOS 27): temporary, see darwin/yabai.nix for when and how to remove.
    # yabai 7.1.25 + macOS 27 scripting-addition patterns (upstream has no macOS
    # 27 support yet: asmvik/yabai#2802), pinned to a reviewed commit.
    yabai-macos27 = {
      url = "github:AhsanFazal/yabai/ad0a12d63f639534a296a1d065b0d04979f1b4db";
      flake = false;
    };
    # kubectl abbreviations for fish
    kubectl-aliases = {
      url = "github:ahmetb/kubectl-aliases";
      flake = false;
    };
    # Neovim configured in Nix
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # one theme and font applied to every app
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # private repo, fetched over SSH; `make switch` fetches it as you first,
    # because root (which runs the switch) can't use your 1Password SSH agent
    uji = {
      url = "git+ssh://git@github.com/uji-labs/uji";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nix-darwin, home-manager, ... }@inputs:
    let
      mkMac =
        { withUji }:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./darwin
            inputs.stylix.darwinModules.stylix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # files already in the way get renamed instead of failing the switch
              home-manager.backupFileExtension = "before-nix";
              home-manager.extraSpecialArgs = { inherit inputs withUji; };
              home-manager.users.karthihegde = import ./home;
            }
          ];
        };
    in
    {
      # named `mac`, not by hostname, so any Mac can switch to it: `make switch`
      darwinConfigurations.mac = mkMac { withUji = true; };
      # first switch on a fresh Mac: uji needs SSH keys from 1Password, which
      # this switch is what installs
      darwinConfigurations.mac-bootstrap = mkMac { withUji = false; };
    };
}
