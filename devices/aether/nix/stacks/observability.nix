{ config, lib, pkgs, ... }:

let
  beszel = pkgs.callPackage ../pkgs/beszel.nix { };
in
{
  systemd.services.beszel-hub.serviceConfig.ExecStartPre = lib.mkForce [
    "${beszel}/bin/beszel-hub migrate up"
    "${beszel}/bin/beszel-hub migrate history-sync"
  ];

  services.beszel.hub = {
    enable = true;
    package = beszel;
    environmentFile = config.sops.secrets."beszel".path;
    environment = {
      APP_URL = "https://metrics.karthihegde.dev";
      TRUSTED_AUTH_HEADER = "Remote-Email";
      TRUSTED_PROXY_IPS = "127.0.0.1";
      USER_EMAIL = "karthihegde@karthihegde.dev";
      DISABLE_SSH = "true";
    };
  };

  services.beszel.agent = {
    enable = true;
    package = beszel;
    smartmon.enable = true;
    environmentFile = config.sops.secrets."beszel-agent".path;
    environment = {
      LISTEN = "127.0.0.1:45876";
      HUB_URL = "http://127.0.0.1:8090";
      DOCKER_HOST = "unix:///run/podman/podman.sock";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6eRZp9WS3c3COpCpdLMbAWBofTxiEjEoDQRu+dzBMI";
    };
  };

  services.caddy.virtualHosts."metrics.karthihegde.dev".extraConfig = ''
    import auth
    handle / {
      redir * /system/1tl9kujf26b2h0x
    }
    request_body {
      max_size 10MB
    }
    reverse_proxy 127.0.0.1:8090 {
      transport http {
        read_timeout 360s
      }
    }
  '';
}
