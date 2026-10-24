{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./firewall.nix
    ./hardware.nix
    ./stacks
  ];

  # every stack runs rootful (system-level) podman: adguardhome needs :53, and
  # dockerSocket is what homepage talks to
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };
  virtualisation.oci-containers.backend = "podman";

  networking.hostName = "aether";
  time.timeZone = "Asia/Kolkata";

  # same key as the old box, so `ssh arch` style access keeps working
  users.users.karthihegde = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4UMMZhJYCmiia27CNCbbu35L36rzqRWfadiH2kliMd"
    ];
  };

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = true;

  services.tailscale.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # stacks publish host ports; the firewall opens each one in its own module
  networking.firewall.enable = true;

  # One SOPS-encrypted dotenv file per stack (devices/aether/nix/secrets/<stack>.env),
  # decrypted at activation into /run/secrets/<stack> and handed to the
  # container as an environment file. Same age key as the Mac; put it at
  # /var/lib/sops-nix/key.txt on aether.
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    # builds shouldn't need the private key just to evaluate the config
    validateSopsFiles = false;
    secrets = lib.genAttrs [
      "caddy"
      "cartero"
      "immich"
      "karakeep"
      "media"
      "obsidian"
      "searchxng"
      "tangled"
    ] (name: {
      sopsFile = ./secrets/${name}.env;
      format = "dotenv";
      mode = "0400";
    });
  };

  # data that used to be `./config`, `./data` next to each compose file lives
  # here now, one directory per stack, created by that stack's module
  environment.etc."stacks/README".text = ''
    /var/lib/stacks/<stack>/  persistent data, one dir per stack
    secrets come from sops: devices/aether/nix/secrets/<stack>.env -> /run/secrets/<stack>
  '';

  system.stateVersion = "26.05";
}
