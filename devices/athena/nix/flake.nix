{
  description = "karthihegde's Mac: nix-darwin for the system, home-manager for the user";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crates-nix.url = "github:uttarayan21/crates.nix";
    hades = {
      url = "path:/Users/karthihegde/Projects/hades";
      flake = false;
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-catppuccin = {
      url = "github:catppuccin/tmux/1612a23174a6771ac466312eb156f83b8b89d907";
      flake = false;
    };
    yabai-macos27 = {
      url = "github:AhsanFazal/yabai/ad8d5adfdc39c76399599ae79a264f2525f6ca5e";
      flake = false;
    };
    kubectl-aliases = {
      url = "github:ahmetb/kubectl-aliases";
      flake = false;
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vellum = {
      url = "github:blackhat-7/vellum.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sonora = {
      url = "github:sonorahq/sonora";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    pared.url = "github:4evy/pared/2.1.0";
    uji = {
      url = "git+ssh://git@github.com/uji-labs/uji";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uji-plugins.url = "git+ssh://git@github.com/uji-labs/uji-plugins";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
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
            inputs.nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-nix";
              home-manager.extraSpecialArgs = { inherit inputs withUji; };
              home-manager.users.karthihegde = import ./home;
            }
          ];
        };
    in
    {
      darwinConfigurations.mac = mkMac { withUji = true; };
      darwinConfigurations.mac-bootstrap = mkMac { withUji = false; };
    };
}
