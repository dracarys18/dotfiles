# Caddy was a host systemd service on the old box (/etc/caddy/Caddyfile), not a
# container, so it stays a service here. Ports 80/443 are not reachable from the
# internet, so certificates come from ACME DNS-01 through Cloudflare — that
# needs the caddy-dns/cloudflare plugin built into caddy.
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

  landing = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>karthihegde.dev</title>
    <style>
      :root { color-scheme: dark; }
      body { margin: 0; font: 16px/1.5 system-ui, -apple-system, sans-serif; background: #0e0e0e; color: #d6d6d6;
             display: grid; place-items: center; min-height: 100vh; }
      main { width: min(880px, 90vw); padding: 3rem 0; }
      h1 { font-size: .8rem; font-weight: 600; letter-spacing: .12em; text-transform: uppercase; color: #6f6f6f; margin: 0 0 1.6rem; }
      ul { list-style: none; margin: 0; padding: 0; display: grid; gap: .7rem;
           grid-template-columns: repeat(auto-fill, minmax(165px, 1fr)); }
      a { display: block; padding: .85rem 1rem; border: 1px solid #242424; border-radius: .6rem;
          color: inherit; text-decoration: none; transition: border-color .12s, background .12s; }
      a:hover, a:focus-visible { border-color: #4a4a4a; background: #161616; outline: none; }
      span { display: block; font-size: .72rem; color: #6a6a6a; margin-top: .15rem; }
    </style>
    </head>
    <body>
    <main>
    <h1>karthihegde.dev</h1>
    <ul>
      <li><a href="https://has.karthihegde.dev/">Home Assistant<span>house</span></a></li>
      <li><a href="https://metrics.karthihegde.dev/">Metrics<span>beszel</span></a></li>
      <li><a href="https://media.karthihegde.dev/">Jellyfin<span>media</span></a></li>
      <li><a href="https://requests.karthihegde.dev/">Seerr<span>requests</span></a></li>
      <li><a href="https://keep.karthihegde.dev/">Karakeep<span>bookmarks</span></a></li>
      <li><a href="https://note.karthihegde.dev/">Obsidian<span>notes</span></a></li>
      <li><a href="https://pdf.karthihegde.dev/">BentoPDF<span>pdf</span></a></li>
      <li><a href="https://search.karthihegde.dev/">SearXNG<span>search</span></a></li>
      <li><a href="https://radarr.karthihegde.dev/">Radarr<span>movies</span></a></li>
      <li><a href="https://sonarr.karthihegde.dev/">Sonarr<span>tv</span></a></li>
      <li><a href="https://prowlarr.karthihegde.dev/">Prowlarr<span>indexers</span></a></li>
      <li><a href="https://torrent.karthihegde.dev/">qBittorrent<span>torrents</span></a></li>
      <li><a href="https://dns.karthihegde.dev/">AdGuard<span>dns</span></a></li>
      <li><a href="https://auth.karthihegde.dev/">Authelia<span>sso</span></a></li>
      <li><a href="https://admin.karthihegde.dev/">Users<span>lldap</span></a></li>
      <li><a href="https://tangled.karthihegde.dev/">Tangled<span>git</span></a></li>
      <li><a href="https://news.karthihegde.dev/">News<span>feeds</span></a></li>
    </ul>
    </main>
    </body>
    </html>
  '';
  # Authelia SSO lands first, then Caddy hands AdGuard its own credential, so
  # the AdGuard login form never appears. The value reaches caddy through
  # systemd's EnvironmentFile (read as root) rather than an imported file:
  # /run/secrets/rendered is root-only and caddy runs as the caddy user.
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

    # CF_API_TOKEN comes from sops: devices/aether/nix/secrets/caddy.env;
    # ADGUARD_BASIC_AUTH is the rendered template next to it
    environmentFile = config.sops.secrets."caddy".path;

    # globalConfig turns the admin API off, so `caddy reload` has nothing to
    # talk to and fails the whole activation. Restart on config changes instead.
    enableReload = false;

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
        reverse_proxy 127.0.0.1:3000 {
          header_up Authorization "{$ADGUARD_BASIC_AUTH}"
        }
      '';

      "keep.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:3069";
      "pdf.karthihegde.dev".extraConfig = ''
        import auth
        reverse_proxy 127.0.0.1:8069
      '';
      "media.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:8096";
      "requests.karthihegde.dev".extraConfig = "reverse_proxy 127.0.0.1:5055";
      "home.karthihegde.dev".extraConfig = ''
        root * ${landing}
        file_server
      '';

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

  # two env files: the CF token and the AdGuard credential
  systemd.services.caddy.serviceConfig.EnvironmentFile = lib.mkForce [
    config.sops.secrets."caddy".path
    config.sops.templates."caddy-adguard.env".path
  ];

  # `admin off` above means there is no /load endpoint, so `caddy reload` always
  # fails and activation reports a failed unit while the old config keeps
  # serving; restart on change instead
  systemd.services.caddy.reloadIfChanged = false;
}
