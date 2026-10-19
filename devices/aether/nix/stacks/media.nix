# ~/Projects/mediastack — media server, *arr apps and the VPN sidecar. The
# tailscale container owns the network namespace qbittorrent and privoxy run
# in, exactly like `network_mode: service:tailscale`.
{
  config,
  lib,
  ...
}:

let
  d = "/var/lib/stacks/mediastack";
  linuxserverEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = "Asia/Kolkata";
  };
  cloudflareDns = [
    "--dns=1.1.1.1"
    "--dns=8.8.8.8"
  ];
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
    "d ${d}/config/jellyfin ${d}/config/radarr ${d}/config/sonarr ${d}/config/prowlarr 0755 root root -"
    "d ${d}/config/qbittorrent ${d}/config/jellyseerr ${d}/config/tailscale ${d}/config/privoxy 0755 root root -"
    "d ${d}/data ${d}/data/media ${d}/data/downloads 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [
    8096 # jellyfin
    7878 # radarr
    8989 # sonarr
    9696 # prowlarr
    8080 # qbittorrent webui, published by the tailscale sidecar
    8118 # tailscale outbound proxy
    6881 # qbittorrent
    5055 # jellyseerr
  ];
  networking.firewall.allowedUDPPorts = [ 6881 ];

  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/jellyfin:/config"
        "${d}/data/media:/data/media"
        "/mnt/media:/tv"
      ];
      ports = [ "8096:8096" ];
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/radarr:/config"
        "${d}/data:/data"
      ];
      ports = [ "7878:7878" ];
      extraOptions = cloudflareDns;
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/sonarr:/config"
        "${d}/data/downloads:/data/downloads"
        "${d}/data/media:/media"
      ];
      ports = [ "8989:8989" ];
      extraOptions = cloudflareDns;
    };

    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      environment = linuxserverEnv;
      volumes = [ "${d}/config/prowlarr:/config" ];
      ports = [ "9696:9696" ];
      extraOptions = cloudflareDns;
    };

    tailscale = {
      image = "tailscale/tailscale:latest";
      environment = {
        TS_EXTRA_ARGS = "--exit-node=100.110.81.102 --accept-routes --exit-node-allow-lan-access --accept-dns=false";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_OUTBOUND_HTTP_PROXY_LISTEN = ":8118";
        TS_USERSPACE = "true";
      };
      # TS_AUTHKEY comes from sops: devices/aether/nix/secrets/media.env
      environmentFiles = [ config.sops.secrets."media".path ];
      volumes = [
        "${d}/config/tailscale:/var/lib/tailscale"
        "${d}/config/tailscale/resolv.conf:/etc/resolv.conf:ro"
        "/dev/net/tun:/dev/net/tun"
      ];
      ports = [
        "8080:8080"
        "8118:8118"
        "6881:6881"
        "6881:6881/udp"
      ];
      extraOptions = [
        "--hostname=qbittorrent-vpn"
        "--dns=193.138.218.74"
        "--network=podman:alias=vpn-tunnel"
        "--cap-add=net_admin"
        "--cap-add=sys_module"
      ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = linuxserverEnv // {
        WEBUI_PORT = "8080";
      };
      volumes = [
        "${d}/config/qbittorrent:/config"
        "${d}/data/downloads:/downloads"
      ];
      dependsOn = [ "tailscale" ];
      extraOptions = [ "--network=container:tailscale" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "QbitTorrent";
        "homepage.icon" = "qbittorrent.png";
        "homepage.href" = "http://torrent.karthihegde.dev/";
        "homepage.description" = "Torrent";
      };
    };

    privoxy = {
      image = "vimagick/privoxy";
      volumes = [ "${d}/config/privoxy/config:/etc/privoxy/config" ];
      dependsOn = [ "tailscale" ];
      extraOptions = [ "--network=container:tailscale" ];
    };

    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      environment = {
        LOG_LEVEL = "info";
        TZ = "Asia/Kolkata";
      };
    };

    jellyseerr = {
      image = "fallenbagel/jellyseerr:latest";
      environment = linuxserverEnv // {
        LOG_LEVEL = "debug";
      };
      volumes = [ "${d}/config/jellyseerr:/app/config" ];
      ports = [ "5055:5055" ];
      extraOptions = [
        "--dns=1.1.1.1"
        "--dns=8.8.4.4"
      ];
    };
  };
}
