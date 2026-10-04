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
    # tmux plugin manager; it installs the other tmux plugins at runtime
    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
  };

  outputs =
    { nix-darwin, home-manager, ... }@inputs:
    {
      # `darwin-rebuild switch --flake ~/dotfiles` picks this by hostname
      darwinConfigurations."KARTHIKEYAs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # files already in the way get renamed instead of failing the switch
            home-manager.backupFileExtension = "before-nix";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.karthihegde = import ./home.nix;
          }
        ];
      };
    };
}
