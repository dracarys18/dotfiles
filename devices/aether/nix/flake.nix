{
  description = "karthihegde's server: NixOS, every ~/Projects stack as podman oci-containers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # same age key as the Mac decrypts these: darwin/secrets.nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, sops-nix, ... }:
    {
      # named `aether`, and not by hostname, so a rebuilt box switches to the same config
      nixosConfigurations.aether = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.sops
        ];
      };
    };
}
