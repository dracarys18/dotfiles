# ~/Projects/adguardhome — this box is the tailnet's resolver, so it is the
# last stack to switch over. AdGuard Home does the filtering per client and
# talks DoH to Cloudflare, with Quad9/Google as fallbacks.
#
# It runs with host networking, unlike every other stack: :53 has to be
# reachable from the LAN and the tailnet, and a published port is DNAT'd
# straight past NixOS's firewall (which only builds an INPUT chain). On the
# host network the queries land on INPUT, where firewall.nix decides that the
# LAN and the tailnet may resolve and the internet may not. Nothing else needs
# the fixed 10.99.0.2 address it used to have.
#
# Planned but not wired up yet: a local recursive resolver (unbound on the
# host at 127.0.0.1:5335) as AGH's upstream, so no third-party resolver sees
# queries. The mvance/unbound container exit-1'd with no diagnostics, so it
# moved out of compose; when it lands, unbound becomes a plain Arch service
# and AGH's upstream is changed in the UI.
#
# Like every other stack here the container is declared and the config file is
# not: AGH is a GUI app and owns /var/lib/stacks/adguardhome/conf itself.
# Upstreams, blocklists and per-client rules are all set in the UI on :4243,
# and the admin password is set there too — none of it is in this repo.
#
# It cannot bind 0.0.0.0:53 any more: podman's DNS (aardvark-dns) holds
# 10.88.0.1:53 on the host stack, and a wildcard bind fails while a specific
# address on the same port is taken. The config therefore lists the addresses
# it serves, which means the tailnet address has to exist before it starts.
{ ... }:

let
  d = "/var/lib/stacks/adguardhome";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/conf 0700 root root -"
    "d ${d}/work 0700 root root -"
  ];

  virtualisation.oci-containers.containers = {
    adguardhome = {
      image = "adguard/adguardhome:latest";
      volumes = [
        "${d}/conf:/opt/adguardhome/conf"
        "${d}/work:/opt/adguardhome/work"
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  systemd.services.podman-adguardhome.after = [ "tailscaled.service" ];
}
