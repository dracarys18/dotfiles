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
  config,
  lib,
  ...
}:

let
  # the LAN, IPv4 and IPv6. The v4 subnet is read back from the interface
  # config, so the address is written once (configuration.nix). The v6 prefix
  # comes from the router's RA and cannot be known at eval time; it changes if
  # the ISP renumbers, and only this line needs updating then.
  # iptables masks the host bits, so 192.168.0.179/24 is added as 192.168.0.0/24
  lanV4 =
    let
      a = lib.head config.networking.interfaces.lan0.ipv4.addresses;
    in
    "${a.address}/${toString a.prefixLength}";
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

    # everything the LAN is allowed to reach except ssh, which is tailnet-only:
    # DNS, caddy, home assistant, matter. Listed as sources rather than ports
    # because the LAN and the WAN share one interface, so a port list cannot
    # tell them apart.
    # extraCommands (not extraInputRules) is the iptables backend's hook: it is
    # spliced into the nixos-fw chain just before the final reject
    extraCommands = ''
      # ssh is tailnet-only. This must come before the DNS exceptions below,
      # since nixos-fw is first-match. The cost is real: with tailscaled down
      # there is no remote way into a headless box.
      iptables -A nixos-fw -i lan0 -p tcp --dport 22 -j DROP
      ip6tables -A nixos-fw -i lan0 -p tcp --dport 22 -j DROP

      # the LAN gets DNS and nothing else. A blanket accept used to be here,
      # but the only thing it was carrying was resolver traffic from two LAN
      # devices: every *.karthihegde.dev record points at a tailnet address, so
      # an off-tailnet client cannot reach the web services regardless, and
      # ollama and the proxies are bound to loopback or the podman bridge.
      iptables -A nixos-fw -s ${lanV4} -p udp --dport 53 -j nixos-fw-accept
      iptables -A nixos-fw -s ${lanV4} -p tcp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p udp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p tcp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p udp --dport 53 -j nixos-fw-accept

      # SSDP: HA's upnp integration learns the router through multicast, and
      # every reply comes back from the gateway's port 1900. Without this the
      # IGD entities work only until the next reboot, because the discovered
      # device list is in memory and re-discovery is rejected.
      iptables -A nixos-fw -s ${lanV4} -p udp --sport 1900 -j nixos-fw-accept

      # mDNS: Matter (matter-server), zeroconf and every discovery-based
      # integration live on multicast 5353. Matter nodes are found by mDNS, so
      # without this a node keeps working only until its cached session expires
      # and then never comes back. Both directions: queries arrive on 5353 and
      # unicast answers leave from 5353.
      iptables -A nixos-fw -s ${lanV4} -p udp --dport 5353 -j nixos-fw-accept
      iptables -A nixos-fw -s ${lanV4} -p udp --sport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p udp --dport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p udp --dport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p udp --sport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p udp --sport 5353 -j nixos-fw-accept

      # containers reach host services over the podman bridge, which no other
      # rule covers — cartero's embedder was timing out on 10.88.0.1:11434
      # because of exactly that. Opened per service rather than by trusting
      # podman0, so a compromised container cannot reach every host port.
      iptables -A nixos-fw -i podman0 -s 10.88.0.0/16 -d 10.88.0.1 -p tcp --dport 11434 -j nixos-fw-accept

      # Homepage's site monitors run inside the homepage container and ask for
      # *.karthihegde.dev, which resolves to whatever tailnet address this box
      # has today. Tailscale routes that address back out tailscale0, where
      # ts-forward drops traffic that did not come from the tailnet, so the
      # monitors time out. Rewrite any 443 request aimed at one of this host's
      # own addresses to the bridge instead: Caddy still sees the original Host
      # header (and serves the matching certificate), and only 443 from podman0
      # is opened, not the whole host. addrtype LOCAL rather than the address
      # itself, so a new tailnet address needs no edit here.
      # -C first: nat rules are not flushed by a firewall reload, so a plain -A
      # would stack a new copy on every switch.
      iptables -t nat -C PREROUTING -i podman0 -s 10.88.0.0/16 -p tcp --dport 443 -m addrtype --dst-type LOCAL -j DNAT --to-destination 10.88.0.1:443 2>/dev/null \
        || iptables -t nat -A PREROUTING -i podman0 -s 10.88.0.0/16 -p tcp --dport 443 -m addrtype --dst-type LOCAL -j DNAT --to-destination 10.88.0.1:443
      iptables -A nixos-fw -i podman0 -s 10.88.0.0/16 -d 10.88.0.1 -p tcp --dport 443 -j nixos-fw-accept
    '';

    # tailscale sends from the tailnet address over an interface that the
    # router never sees, so a strict reverse-path check would drop it
    checkReversePath = "loose";

    logRefusedConnections = false;
  };

  # the live box answered password logins from the internet for a while
  # sshd would otherwise add 22 to allowedTCPPorts, i.e. open to the world; the
  # tailnet interface is now the only way in
  services.openssh.openFirewall = false;

  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    MaxAuthTries = 3;
    AllowUsers = [ "karthihegde" ];
  };
}
