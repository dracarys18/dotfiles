{
  description = "karthihegde's server: NixOS, every ~/Projects stack as podman oci-containers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # same age key as the Mac decrypts these: darwin/secrets.nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # push a config to the box over ssh, with an automatic rollback when the
    # new generation doesn't come up. Replaces rsync + nixos-rebuild over ssh
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      deploy-rs,
    }:
    {
      # named `aether`, and not by hostname, so a rebuilt box switches to the same config
      nixosConfigurations.aether = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          sops-nix.nixosModules.sops
        ];
      };

      # `nix run .#deploy -- .#aether --remote-build` from this directory, or
      # `make deploy` from the repo root. This Mac is aarch64-darwin and cannot
      # build x86_64-linux, so the box builds its own closure over ssh.
      apps.aarch64-darwin.deploy = {
        type = "app";
        program = "${deploy-rs.packages.aarch64-darwin.deploy-rs}/bin/deploy";
      };

      deploy = {
        nodes.aether = {
          hostname = "aether";
          profiles.system = {
            # the box refuses root logins, so deploy-rs ssh's as this user and
            # sudo's to root; make passes --interactive-sudo so the server's
            # password is asked for rather than stored as a NOPASSWD rule
            sshUser = "karthihegde";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.aether;
          };
          remoteBuild = true;
        };
        # evaluate every profile so a broken config fails before it is pushed
        checks = builtins.mapAttrs (
          _system: deployLib: deployLib.deployChecks self.deploy
        ) deploy-rs.lib;
      };
    };
}
