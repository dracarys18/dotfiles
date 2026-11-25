{ config, lib, pkgs, ... }:

let
  auth = ''
    (auth) {
      forward_auth 127.0.0.1:9091 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        header_up -Authorization
      }
    }

    (proxy) {
      reverse_proxy 127.0.0.1:{args[0]}
    }

    (gated) {
      import auth
      reverse_proxy 127.0.0.1:{args[0]}
    }
  '';

in
{
  sops.secrets."adguardhome/basic_auth" = {
    sopsFile = ../secrets/adguardhome.yaml;
    key = "basic_auth";
    mode = "0400";
  };

  sops.secrets."caddy".restartUnits = [ "caddy.service" ];

  sops.templates."caddy-adguard.env".restartUnits = [ "caddy.service" ];

  sops.templates."caddy-adguard.env".content = ''
    ADGUARD_BASIC_AUTH="${config.sops.placeholder."adguardhome/basic_auth"}"
  '';


  systemd.services.caddy.serviceConfig = {
    RuntimeDirectory = "caddy";
    RuntimeDirectoryPreserve = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK"
    ];
    RestrictNamespaces = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    CapabilityBoundingSet = [
      "CAP_NET_BIND_SERVICE"
      "CAP_NET_ADMIN"
    ];
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
      hash = "sha256-4QbLyUaZ+5P+ZOotM6D3w275RDD/NaprzMS2orX7I6I=";
    };

    environmentFile = config.sops.secrets."caddy".path;

    globalConfig = ''
      admin unix//run/caddy/admin.sock
      grace_period 30s
      acme_dns cloudflare {
        api_token {env.CF_API_TOKEN}
      }
    '';

    extraConfig = auth;
  };


  systemd.tmpfiles.rules = [
    "d /run/caddy 0750 caddy caddy -"
    "d /var/lib/stacks/caddy 0755 root root -"
  ];

  systemd.services.caddy.serviceConfig.EnvironmentFile = lib.mkForce [
    config.sops.secrets."caddy".path
    config.sops.templates."caddy-adguard.env".path
  ];

  systemd.services.caddy.serviceConfig.ExecReload = lib.mkForce [
    ""
    "${config.services.caddy.package}/bin/caddy reload --config ${config.services.caddy.configFile} --adapter caddyfile --address unix//run/caddy/admin.sock --force"
  ];
}
