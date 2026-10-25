# Caddy was a host systemd service on the old box (/etc/caddy/Caddyfile), not a
# container, so it stays a service here. Ports 80/443 are not reachable from the
# internet, so certificates come from ACME DNS-01 through Cloudflare — that
# needs the caddy-dns/cloudflare plugin built into caddy.
{ config, pkgs, ... }:

let
  auth = ''
    (auth) {
      forward_auth 127.0.0.1:9091 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
      }
    }
  '';
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
      hash = "sha256-UPd4CWjm8Cq5EZ9OkBCglE23hD8+przFBSw8Ey6zMz8=";
    };

    # CF_API_TOKEN comes from sops: devices/aether/nix/secrets/caddy.env
    environmentFile = config.sops.secrets."caddy".path;

    globalConfig = ''
      admin off
      acme_dns cloudflare {
        api_token {env.CF_API_TOKEN}
      }
    '';

    # the `import auth` snippet the Caddyfile used
    extraConfig = auth;

    virtualHosts = {
      "note.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:5984";

      "dns.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:3000
      '';

      "keep.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:3069";
      "pdf.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:8069";
      "feed.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:8034";
      "media.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:8096";
      "requests.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:5055";
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

      # qbittorrent lives in the media stack's VPN sidecar, which publishes its
      # webui on the host's loopback — no need to reach across the tailnet
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

  # every stack publishes on 127.0.0.1 and caddy is the only way in from the
  # LAN or the tailnet, so the port lists that used to live here are gone;
  # firewall.nix holds the policy

  systemd.tmpfiles.rules = [
    "d /var/lib/stacks/caddy 0755 root root -"
  ];

  # `admin off` above means there is no /load endpoint, so `caddy reload` always
  # fails and activation reports a failed unit while the old config keeps
  # serving; restart on change instead
  systemd.services.caddy.reloadIfChanged = false;
}
