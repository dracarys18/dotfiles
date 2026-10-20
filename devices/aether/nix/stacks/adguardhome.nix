# ~/Projects/adguardhome — this box is the tailnet's resolver, so it is the
# last stack to switch over. AdGuard Home does the filtering per client and
# talks DoH to Cloudflare, with Quad9/Google as fallbacks. The network exists
# so the container has a fixed address the rest of the stacks can point at.
#
# Planned but not wired up yet: a local recursive resolver (unbound on the
# host at 127.0.0.1:5335) as AGH's upstream, so no third-party resolver sees
# queries. The mvance/unbound container exit-1'd with no diagnostics, so it
# moved out of compose; when it lands, unbound becomes a plain Arch service
# and AGH's upstream is changed in the UI.
#
# The admin password is not in this repo: first start serves the setup wizard
# on :4243, and the UI owns /var/lib/stacks/adguardhome/conf/AdGuardHome.yaml
# from then on.
{
  config,
  lib,
  ...
}:

let
  d = "/var/lib/stacks/adguardhome";
  podman = "${config.virtualisation.podman.package}/bin/podman";
  network = "adguardhome_net";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/conf 0700 root root -"
    "d ${d}/work 0700 root root -"
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
            ${podman} network create --subnet 10.99.0.0/24 ${network}
        '';
      };
    }
    // lib.genAttrs [ "podman-adguardhome" ] (_: {
      requires = [ "podman-network-${network}.service" ];
      after = [ "podman-network-${network}.service" ];
    });

  networking.firewall.allowedTCPPorts = [ 53 4243 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.containers = {
    adguardhome = {
      image = "adguard/adguardhome:latest";
      volumes = [
        "${d}/conf:/opt/adguardhome/conf"
        "${d}/work:/opt/adguardhome/work"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "4243:3000"
      ];
      extraOptions = [
        "--network=${network}"
        "--ip=10.99.0.2"
      ];
    };
  };
}
