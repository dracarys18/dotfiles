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
  # dockerSocket is what homepage talks to. nixpkgs creates the default network
  # with dns_enabled = false, so containers cannot resolve each other by name
  # (karakeep-web asking for karakeep-chrome-1 gets ENOTFOUND) — every stack
  # that talks to a sibling relies on this
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

  # On a first activation the podman units start before systemd-tmpfiles has
  # created /var/lib/stacks/**, so each container dies with
  # "statfs <path>: no such file or directory" and hits start-limit-hit. Create
  # every bind-mount source in the unit itself; named volumes are podman's job.
  # Sources that already exist are left alone: some are not directories at all
  # (/run/podman/podman.sock, /etc/localtime), and mkdir -p fails on those.
  systemd.services = lib.mapAttrs' (
    name: container:
    lib.nameValuePair "podman-${name}" {
      preStart = lib.concatMapStringsSep "\n" (
        volume:
        let
          host = lib.head (lib.splitString ":" volume);
        in
        lib.optionalString (lib.hasPrefix "/" host)
          "[ -e ${lib.escapeShellArg host} ] || mkdir -p ${lib.escapeShellArg host}"
      ) container.volumes;
    }
  ) config.virtualisation.oci-containers.containers
  // {
    # systemd deletes RuntimeDirectory=/run/tailscale when a unit stops, and on
    # a restart that deletion can land *after* the new daemon has bound its
    # socket, leaving tailscaled running with no control socket
    tailscaled.serviceConfig.RuntimeDirectoryPreserve = "yes";

    # the media stack's container is itself named "tailscale", and nixpkgs
    # gives every container RuntimeDirectory=/run/<name> — the same path the
    # daemon keeps its control socket in, so stopping that container deleted it
    "podman-tailscale".serviceConfig.RuntimeDirectory = lib.mkForce "podman-tailscale";

    # ollama listens on the podman bridge so containers can reach it as
    # host.docker.internal, but that bridge is created by netavark when the
    # first container starts, which is later than ollama wants to bind — so the
    # first attempt fails with "cannot assign requested address" and the unit
    # dies. Retrying until the bridge exists also covers podman recreating it.
    ollama = {
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };

    # the DIMMs forget their colour when the PSU is unplugged, so re-apply "off"
    # at every boot. Devices 0 and 1 are the two DRAM modules; if enumeration
    # order ever changes the worst case is that the board headers go dark.
    openrgb-ram = {
      description = "switch off the Corsair DIMM RGB";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.openrgb}/bin/openrgb --noautoconnect -d 0 -m Direct -c 000000 || true
        ${pkgs.openrgb}/bin/openrgb --noautoconnect -d 1 -m Direct -c 000000 || true
      '';
    };
  };

  networking.hostName = "aether";
  time.timeZone = "Asia/Kolkata";

  # AdGuard binds this address explicitly (stacks/adguardhome.nix), so a DHCP
  # lease that moved would take DNS down with it. Pinned here instead of as a
  # router reservation so the address is part of the config.
  #
  # The name is pinned to the MAC rather than used as enp4s0/enp5s0: predictable
  # names encode the PCIe bus number, and fitting a second NVMe renumbered the
  # bus once already, which left the box with no IPv4 at all
  systemd.network.links."10-lan" = {
    matchConfig.MACAddress = "30:56:0f:85:2e:07";
    linkConfig.Name = "lan0";
  };

  networking.useDHCP = false;
  networking.interfaces.lan0.useDHCP = false;
  networking.interfaces.lan0.ipv4.addresses = [
    {
      address = "192.168.0.179";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  # HA's bluetooth integration talks to bluetoothd over D-Bus; without this the
  # radio shows up as hci0 but nothing can manage it
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # the media stack's tailscale sidecar runs with --device /dev/net/tun; the
  # device only appears once the module is loaded, and without it podman fails
  # to create the container (exit 125) and the whole activation rolls back
  # tun: the media stack's tailscale sidecar. i2c: OpenRGB reaches the Corsair
  # DIMMs' RGB controller over the SMBus, which only works once the kernel stops
  # honouring ACPI's claim on that region — hence the kernel parameter. Without
  # it i2c-piix4 loads but finds no devices at all (decode-dimms sees 0 DIMMs).
  boot.kernelModules = [
    "tun"
    "i2c-dev"
    "i2c-piix4"
  ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  environment.systemPackages = [ pkgs.openrgb ];

  # the box is UEFI: ESP on nvme0n1p1. This cannot live in hardware.nix because
  # `make bootstrap` regenerates that file from nixos-generate-config, which
  # emits no bootloader settings at all
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    # the ESP is only 511M and every generation adds a bootloader entry, so cap
    # them rather than letting twenty pile up
    systemd-boot.configurationLimit = 5;
  };

  # same key as the old box, so `ssh arch` style access keeps working
  users.users.karthihegde = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4UMMZhJYCmiia27CNCbbu35L36rzqRWfadiH2kliMc"
    ];
  };

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = true;

  services.tailscale.enable = true;

  # cartero's embedder talks to ollama at host.docker.internal:11434, which in
  # a container is the podman gateway. Binding that address (rather than
  # 0.0.0.0) keeps 11434 off the LAN and the tailnet, which is the same
  # ip:port rule every other service on this box follows. The host can still
  # reach it, because 10.88.0.1 is a local address.
  services.ollama = {
    enable = true;
    host = "10.88.0.1";
  };

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

  # The 1 TB Crucial P3 that used to boot archmaestro: all container state and
  # the media library live there, so the Verbatim is boot-only. Two subvolumes
  # of one filesystem, so a runaway download cannot fill the filesystem
  # Postgres lives on. Deliberately no `nofail`: if this disk is missing, the
  # containers must fail to start rather than come up against empty state.
  fileSystems."/var/lib/stacks" = {
    device = "/dev/disk/by-uuid/fa207171-ce84-40fc-b066-19f2736aca45";
    fsType = "btrfs";
    options = [
      "subvol=@stacks"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-uuid/fa207171-ce84-40fc-b066-19f2736aca45";
    fsType = "btrfs";
    options = [
      "subvol=@media"
      "noatime"
    ];
  };

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
      "karakeep"
      "media"
      "obsidian"
      "searchxng"
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
