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

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
    dockerSocket.enable = true;
  };
  virtualisation.oci-containers.backend = "podman";

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
    tailscaled.serviceConfig.RuntimeDirectoryPreserve = "yes";

    "podman-tailscale".serviceConfig.RuntimeDirectory = lib.mkForce "podman-tailscale";

    ollama = {
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };

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
    "1.0.0.1"
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "127.0.0.1#adguard.aether.internal"
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
      ];
      DNSOverTLS = "yes";
      DNSSEC = "yes";
      Domains = [ "~." ];
    };
  };

  services.dnscrypt-proxy = {
    enable = true;
    upstreamDefaults = false;
    settings = {
      listen_addresses = [ "127.0.0.1:5300" ];
      ipv4_servers = true;
      ipv6_servers = true;
      dnscrypt_servers = true;
      doh_servers = false;
      odoh_servers = false;
      require_dnssec = true;
      cache = true;
      ignore_system_dns = true;
      timeout = 2000;
      bootstrap_resolvers = [
        "[2606:4700:4700::1111]:53"
        "1.1.1.1:53"
      ];
      server_names = [
        "dnscry.pt-mumbai02-ipv4"
        "dnscry.pt-bengaluru-ipv4"
      ];
      static."dnscry.pt-mumbai02-ipv4".stamp = "sdns://AQcAAAAAAAAADDE1Ny4yMC4yNy43OSCWqeT_u1nn0f3mZBAXCN7K40kyMWyMgma2VqLqJhijIhkyLmRuc2NyeXB0LWNlcnQuZG5zY3J5LnB0";
      static."dnscry.pt-bengaluru-ipv4".stamp = "sdns://AQcAAAAAAAAADzE2MC4xOTEuMTgyLjIxNiDM3lhIXzCtFbHampFM4K_NDUnKalgxd72L-5ye1X4qExkyLmRuc2NyeXB0LWNlcnQuZG5zY3J5LnB0";
      static."dnscry.pt-anon-bengaluru-ipv4".stamp = "sdns://gQ8xNjAuMTkxLjE4Mi4yMTY";
      static."dnscry.pt-anon-bengaluru-ipv6".stamp = "sdns://gRZbMjQwMTpkNGUwOjE6ZjdmZDo6NTNd";
      static."dnscry.pt-anon-mumbai02-ipv4".stamp = "sdns://gQwxNTcuMjAuMjcuNzk";
      static."dnscry.pt-anon-mumbai02-ipv6".stamp = "sdns://gRFbMjYwMjpmYTA4OjU6Ojc1XQ";
      anonymized_dns.routes = [
        {
          server_name = "dnscry.pt-bengaluru-ipv4";
          via = [
            "dnscry.pt-anon-mumbai02-ipv4"
            "dnscry.pt-anon-mumbai02-ipv6"
          ];
        }
        {
          server_name = "dnscry.pt-mumbai02-ipv4";
          via = [
            "dnscry.pt-anon-bengaluru-ipv4"
            "dnscry.pt-anon-bengaluru-ipv6"
          ];
        }
      ];
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  boot.kernelModules = [
    "tun"
    "i2c-dev"
    "i2c-piix4"
  ];
  boot.kernelParams = [
    "acpi_enforce_resources=lax"
    "slab_nomerge"
    "page_alloc.shuffle=1"
    "randomize_kstack_offset=on"
    "init_on_alloc=1"
    "vsyscall=none"
  ];

  programs.fish.enable = true;

  environment.systemPackages = [
    pkgs.openrgb
    pkgs.fastfetch
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    systemd-boot.memtest86.enable = true;
    systemd-boot.configurationLimit = 2;
  };

  users.users.karthihegde = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4UMMZhJYCmiia27CNCbbu35L36rzqRWfadiH2kliMc"
    ];
  };

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = "Defaults use_pty";

  services.openssh.settings = {
    AllowAgentForwarding = false;
    PermitTunnel = "no";
    ClientAliveInterval = 300;
    ClientAliveCountMax = 2;
    X11Forwarding = false;
    AllowTcpForwarding = "no";
    MaxStartups = "10:30:60";
  };

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.perf_event_paranoid" = 3;
    "kernel.kexec_load_disabled" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
  };

  security.lockKernelModules = true;
  security.protectKernelImage = true;

  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
    "firewire-core"
    "firewire-ohci"
    "firewire-sbp2"
  ];

  services.tailscale.enable = true;

  services.ollama = {
    enable = true;
    host = "10.88.0.1";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ];
  };

  networking.firewall.enable = true;

  fileSystems."/var/lib/stacks" = {
    device = "/dev/disk/by-uuid/fa207171-ce84-40fc-b066-19f2736aca45";
    fsType = "btrfs";
    options = [
      "subvol=@stacks"
      "compress=zstd"
      "noatime"
    ];
  };

  sops = {
    useSystemdActivation = true;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    validateSopsFiles = false;
    secrets = lib.genAttrs [
      "beszel"
      "beszel-agent"
      "caddy"
      "cartero"
      "gatus"
      "homepage"
      "media"
      "obsidian"
      "postgres"
      "searchxng"
      "shiori"
      "tangled"
      "tangled-knot"
    ] (name: {
      sopsFile = ./secrets/${name}.env;
      format = "dotenv";
      mode = "0400";
    });
  };

  environment.etc."stacks/README".text = ''
    /var/lib/stacks/<stack>/  persistent data, one dir per stack
    secrets come from sops: devices/aether/nix/secrets/<stack>.env -> /run/secrets/<stack>
  '';

  services.journald.extraConfig = "SystemMaxUse=1G";

  system.stateVersion = "26.05";
}
