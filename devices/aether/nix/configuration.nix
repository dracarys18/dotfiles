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

  # This ISP hijacks plain UDP DNS, not just its own resolver: a query sent to
  # j.root-servers.net for x1337x.cc came back in 2 ms with 202.83.21.15, which
  # that server does not answer for, while the same lookup over IPv6 or over
  # TLS gives Cloudflare's 104.21.83.238. Every destination on 53/udp is being
  # answered by the ISP, so plain recursion is no safer here than forwarding.
  #
  # Recursion over TCP does work here — the interception is UDP-only, and a
  # tcp-upstream unbound resolved the domain honestly when tested — but it was
  # dropped on purpose: it costs a fresh TCP connection per authoritative hop,
  # ~600ms on a cold name, to keep queries away from a third-party resolver.
  # This box forwards instead.
  #
  # unbound is therefore the one resolver the host, the containers (via
  # resolved) and AdGuard Home ask. It caches and validates DNSSEC locally, and
  # forwards upstream over TLS, where an injected answer cannot be signed.
  # resolved keeps running because containers get DNS through it, but it no
  # longer does TLS itself and leaves validation to unbound.
  #
  # The deploy path uses the IP from ~/.ssh/config, so a resolver outage cannot
  # lock the box out of itself.
  services.unbound = {
    enable = true;
    settings = {
      server = {
        # AdGuard Home runs with --network=host, so loopback reaches it. Nothing
        # else may: no firewall hole is needed for this port.
        interface = [ "127.0.0.1" ];
        port = 5335;
        access-control = [ "127.0.0.0/8 allow" ];
        harden-glue = true;
        harden-dnssec-stripped = true;
        val-clean-additional = true;
        prefetch = true;
        # Cloudflare answers with a 300s TTL; caching that for an hour would
        # make record changes crawl, so keep the floor low and only cap the top
        cache-min-ttl = 300;
        cache-max-ttl = 86400;
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "9.9.9.9@853#dns.quad9.net"
          ];
        }
      ];
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [ "127.0.0.1:5335" ];
      DNSOverTLS = "no";
      DNSSEC = "no";
      Domains = [ "~." ];
    };
  };

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

  # fish is the login shell, same as the Mac. The NixOS module is needed as
  # well: it puts fish in /etc/shells and writes /etc/fish/config.fish, while
  # home-manager only writes the user's own config.
  programs.fish.enable = true;

  environment.systemPackages = [
    pkgs.openrgb
    # neofetch is gone from nixpkgs (unmaintained upstream); fastfetch is the
    # maintained successor. `neowofetch` from the hyfetch package is the
    # faithful look-alike if that is what you want instead.
    pkgs.fastfetch
  ];

  # the box is UEFI: ESP on nvme0n1p1. This cannot live in hardware.nix because
  # `make bootstrap` regenerates that file from nixos-generate-config, which
  # emits no bootloader settings at all
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    # memtest86+ in the boot menu: the only way to cover every cell of the 32G
    # kit, which memtester inside the running system cannot do
    systemd-boot.memtest86.enable = true;
    # the ESP is only 511M and every generation adds a bootloader entry, so cap
    # them rather than letting twenty pile up
    systemd-boot.configurationLimit = 2;
  };

  # same key as the old box, so `ssh arch` style access keeps working
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
  security.sudo.wheelNeedsPassword = true;

  # SSH extras from the hardening checklist. The rest of it (no password auth,
  # no root login, MaxAuthTries 3, modern kex/ciphers, AllowUsers) is already
  # on; AllowTcpForwarding stays enabled on purpose.
  services.openssh.settings = {
    AllowAgentForwarding = false;
    PermitTunnel = "no";
    ClientAliveInterval = 300;
    ClientAliveCountMax = 2;
  };

  # Kernel/network hardening from the same checklist. rp_filter is deliberately
  # NOT set: tailscale needs asymmetric routing to work.
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.tcp_syncookies" = 1;
  };

  # no firewire on this box, and these four are only ever loaded by an attacker
  # or a very exotic client; nothing here uses them
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
      "homepage"
      "karakeep"
      "media"
      "obsidian"
      "searchxng"
      "tangled"
      "tangled-knot"
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
