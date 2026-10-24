# The network policy from the archmaestro post-mortem: nothing is reachable
# from the internet except torrent peers and tailscale's own port. The LAN and
# the tailnet get everything; everything else is refused.
#
# NixOS's iptables firewall only builds an INPUT chain (nixos-fw) and never
# touches FORWARD, so a container that publishes on 0.0.0.0 is invisible to it
# — podman DNATs the packet straight through. That is why every stack publishes
# on 127.0.0.1, and why AdGuard Home and Home Assistant run with host
# networking: their ports land on INPUT, where this policy can scope them.
{
  ...
}:

let
  # the LAN, IPv4 and IPv6. The v6 prefix comes from the router's RA and will
  # change if the ISP renumbers; update it here when that happens
  lanV4 = "192.168.0.0/24";
  lanV6 = "2406:7400:54:c7f3::/64";
in
{
  networking.firewall = {
    enable = true;

    # tailscale0 carries only tailnet traffic; lo is trusted by default
    trustedInterfaces = [ "tailscale0" ];

    # the only ports the whole internet may reach
    allowedTCPPorts = [ 6881 ];
    allowedUDPPorts = [
      6881 # qbittorrent peers
      41641 # tailscale
    ];

    # everything the LAN is allowed to reach: ssh, DNS, caddy, home assistant,
    # matter, privoxy. Listed as sources rather than ports because the LAN and
    # the WAN share one interface, so a port list cannot tell them apart.
    # extraCommands (not extraInputRules) is the iptables backend's hook: it is
    # spliced into the nixos-fw chain just before the final reject
    extraCommands = ''
      iptables -A nixos-fw -s ${lanV4} -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -j nixos-fw-accept
    '';

    # tailscale sends from the tailnet address over an interface that the
    # router never sees, so a strict reverse-path check would drop it
    checkReversePath = "loose";

    logRefusedConnections = false;
  };

  # the live box answered password logins from the internet for a while
  # sshd would otherwise add 22 to allowedTCPPorts, i.e. open to the world; the
  # LAN rule above and the tailnet interface are the only ways in
  services.openssh.openFirewall = false;

  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    MaxAuthTries = 3;
    AllowUsers = [ "karthihegde" ];
  };
}
