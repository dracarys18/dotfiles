# ~/Projects/adguardhome — this box is the tailnet's resolver, so it is the
# last stack to switch over. AdGuard Home does the filtering per client,
# unbound does the recursion (no third-party DNS provider sees queries) and
# is what AGH uses as its only upstream: 10.99.0.3:53. Both containers need
# fixed addresses, which is why this module creates a network before them.
#
# The admin password is not in this repo: first start serves the setup wizard
# on :4243, and the UI owns /var/lib/stacks/adguardhome/conf/AdGuardHome.yaml
# from then on. Only unbound's config is declarative, because unbound never
# writes to it.
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
    "d ${d}/unbound 0755 root root -"
    # copied from the repo on change; unbound does not rewrite it
    "C ${d}/unbound/unbound.conf 0644 root root - ${./adguardhome/unbound.conf}"
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
    // lib.genAttrs [ "podman-adguardhome" "podman-unbound" ] (_: {
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

    unbound = {
      image = "mvance/unbound:latest";
      volumes = [ "${d}/unbound/unbound.conf:/opt/unbound/etc/unbound/unbound.conf" ];
      extraOptions = [
        "--network=${network}"
        "--ip=10.99.0.3"
      ];
    };
  };
}
