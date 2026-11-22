{
  description = "karthihegde's server: NixOS, every ~/Projects stack as podman oci-containers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      deploy-rs,
      ...
    }@inputs:
    {
      nixosConfigurations.aether = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.karthihegde = ./home;
          }
        ];
      };

      apps.aarch64-darwin.deploy = {
        type = "app";
        program = "${deploy-rs.packages.aarch64-darwin.deploy-rs}/bin/deploy";
      };

      deploy.nodes.aether = {
        hostname = "aether";
        profiles.system = {
          sshUser = "karthihegde";
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.aether;
        };
        remoteBuild = true;
        magicRollback = false;
      };

    };
}
