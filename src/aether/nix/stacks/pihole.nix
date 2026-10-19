# ~/Projects/pi-hole — this box is the tailnet's resolver, so it is the last
# stack to switch over. pihole and cloudflared need fixed addresses on their
# own network, which is why this module creates one before the containers.
{
  config,
  lib,
  ...
}:

let
  d = "/var/lib/stacks/pihole";
  podman = "${config.virtualisation.podman.package}/bin/podman";
  network = "pihole_net";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/etc-pihole 0755 root root -"
  ];

  systemd.services =
    {
      "podman-network-${network}" = {
        description = "podman network ${network}";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${podman} network exists ${network} ||
            ${podman} network create --subnet 172.27.0.0/16 ${network}
        '';
      };
    }
    // lib.genAttrs [ "podman-pihole" "podman-cloudflared" ] (_: {
      requires = [ "podman-network-${network}.service" ];
      after = [ "podman-network-${network}.service" ];
    });

  networking.firewall.allowedTCPPorts = [ 53 4242 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = "UTC";
        # cloudflared below, at 172.27.0.3
        FTLCONF_dns_upstreams = "172.27.0.3#5054";
      };
      # FTLCONF_webserver_api_password is a secret: src/aether/nix/secrets/pihole.env
      environmentFiles = [ config.sops.secrets."pihole".path ];
      volumes = [ "${d}/etc-pihole:/etc/pihole" ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "4242:80"
      ];
      extraOptions = [
        "--network=${network}"
        "--ip=172.27.0.2"
        "--cap-add=NET_ADMIN"
        "--cap-add=SYS_TIME"
        "--cap-add=SYS_NICE"
      ];
    };

    cloudflared = {
      image = "cloudflare/cloudflared:2026.1.2";
      cmd = [
        "proxy-dns"
        "--port"
        "5054"
        "--address"
        "0.0.0.0"
        "--upstream"
        "https://dns10.quad9.net/dns-query"
      ];
      extraOptions = [
        "--network=${network}"
        "--ip=172.27.0.3"
      ];
    };
  };
}
