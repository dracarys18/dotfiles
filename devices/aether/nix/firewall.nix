{
  config,
  lib,
  ...
}:

let
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

    trustedInterfaces = [ "tailscale0" ];

    allowedTCPPorts = [ 6881 ];
    allowedUDPPorts = [
      6881
      41641
    ];

    extraCommands = ''
      iptables -A nixos-fw -i lan0 -p tcp --dport 22 -j DROP
      ip6tables -A nixos-fw -i lan0 -p tcp --dport 22 -j DROP

      iptables -t raw -C PREROUTING ! -i lo -p tcp --dport 18555 -j DROP 2>/dev/null \
        || iptables -t raw -I PREROUTING 1 ! -i lo -p tcp --dport 18555 -j DROP
      ip6tables -t raw -C PREROUTING ! -i lo -p tcp --dport 18555 -j DROP 2>/dev/null \
        || ip6tables -t raw -I PREROUTING 1 ! -i lo -p tcp --dport 18555 -j DROP

      iptables -A nixos-fw -s ${lanV4} -p udp --dport 53 -j nixos-fw-accept
      iptables -A nixos-fw -s ${lanV4} -p tcp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p udp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p tcp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p udp --dport 53 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p tcp --dport 53 -j nixos-fw-accept

      iptables -A nixos-fw -s ${lanV4} -p udp --sport 1900 -j nixos-fw-accept

      iptables -A nixos-fw -s ${lanV4} -p udp --dport 5353 -j nixos-fw-accept
      iptables -A nixos-fw -s ${lanV4} -p udp --sport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p udp --dport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p udp --dport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s ${lanV6} -p udp --sport 5353 -j nixos-fw-accept
      ip6tables -A nixos-fw -s fe80::/10 -p udp --sport 5353 -j nixos-fw-accept

      iptables -A nixos-fw -i podman0 -s 10.88.0.0/16 -p tcp -m multiport --dports 443,11434 -j nixos-fw-accept

    '';

    checkReversePath = "loose";

    logRefusedConnections = false;
  };

  services.openssh.openFirewall = false;

  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    MaxAuthTries = 3;
    AllowUsers = [ "karthihegde" ];
  };
}
