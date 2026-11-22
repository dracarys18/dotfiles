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
  '';

in
{
  sops.secrets."adguardhome/basic_auth" = {
    sopsFile = ../secrets/adguardhome.yaml;
    key = "basic_auth";
    mode = "0400";
  };

  sops.templates."caddy-adguard.env".restartUnits = [ "caddy.service" ];

  sops.templates."caddy-adguard.env".content = ''
    ADGUARD_BASIC_AUTH="${config.sops.placeholder."adguardhome/basic_auth"}"
  '';


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

    virtualHosts = {
      "note.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:5984";

      "dns.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:3000 {
          header_up Authorization "{$ADGUARD_BASIC_AUTH}"
        }
      '';

      "fit.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:3670";

      "keep.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:8095 {
          header_up Remote-User shiori
        }
      '';
      "pdf.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:8069
      '';
      "media.karthihegde.dev".extraConfig = ''
        @plainRoot {
          path /
          not header Referer */sso/OIDC/Callback/*
        }
        redir @plainRoot /sso/OIDC/Start/authelia 302
        reverse_proxy 127.0.0.1:8096
      '';
      "requests.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:5055 {
          header_up X-Api-Key {env.SEERR_API_KEY}
        }
      '';
      "home.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:3669";

      "auth.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:9091";
      "search.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:6996";

      "radarr.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:7878
      '';

      "sonarr.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:8989
      '';

      "prowlarr.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:9696
      '';

      "torrent.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:8080
      '';

      "has.karthihegde.dev".extraConfig = ''
        reverse_proxy 127.0.0.1:8123 {
          header_up Host {host}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto "https"
        }
      '';
    };
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
