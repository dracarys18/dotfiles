{
  config,
  lib,
  pkgs,
  ...
}:

let
  d = "/var/lib/stacks/mediastack";
  linuxserverEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = "Asia/Kolkata";
  };
  resolvConf = pkgs.writeText "mediastack-resolv.conf" ''
    nameserver 193.138.218.74
  '';

  ssoOidc = pkgs.fetchzip {
    url = "https://github.com/aussierk/jellyfin-plugin-oidc/releases/download/v2.1.0.1/oidc-rbac.zip";
    hash = "sha256-EZ16RNEIzDgUCSH1GnDzYiWLUeHLhQyrhJygLXZjvTM=";
    stripRoot = false;
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
    "d ${d}/config/jellyfin 0755 root root -"
    "d ${d}/config/radarr 0755 root root -"
    "d ${d}/config/sonarr 0755 root root -"
    "d ${d}/config/prowlarr 0755 root root -"
    "d ${d}/config/qbittorrent 0755 root root -"
    "d ${d}/config/seerr 0775 1000 1000 -"
    "d ${d}/config/tailscale 0755 root root -"
    "d ${d}/data 0755 root root -"
    "d ${d}/data/media 0755 root root -"
    "d ${d}/data/media/movies 0775 1000 1000 -"
    "d ${d}/data/media/tv 0775 1000 1000 -"
    "d ${d}/data/downloads 0775 1000 1000 -"
  ];

  sops.secrets."jellyfin/client_secret" = {
    sopsFile = ../secrets/authelia.yaml;
    key = "jellyfin_client_secret";
    uid = 1000;
    gid = 1000;
    mode = "0400";
    restartUnits = [ "podman-jellyfin.service" ];
  };


  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      extraOptions = [ "--pull=newer" ];
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/jellyfin:/config"
        "${d}/data/media:/data/media"
        "${ssoOidc}:/config/data/plugins/Jellyfin.Plugin.OIDC:ro"
        "${./media/Jellyfin.Plugin.OIDC.xml}:/config/data/plugins/configurations/Jellyfin.Plugin.OIDC.xml:ro"
        "${config.sops.secrets."jellyfin/client_secret".path}:/run/secrets/jellyfin/client_secret:ro"
      ];
      ports = [ "127.0.0.1:8096:8096" ];
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      extraOptions = [ "--pull=newer" ];
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/radarr:/config"
        "${d}/data:/data"
      ];
      ports = [ "127.0.0.1:7878:7878" ];
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr:develop";
      extraOptions = [ "--pull=newer" ];
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/sonarr:/config"
        "${d}/data:/data"
      ];
      ports = [ "127.0.0.1:8989:8989" ];
    };

    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      extraOptions = [ "--pull=newer" ];
      environment = linuxserverEnv;
      volumes = [ "${d}/config/prowlarr:/config" ];
      ports = [ "127.0.0.1:9696:9696" ];
    };

    tailscale = {
      image = "tailscale/tailscale:latest";
      environment = {
        TS_EXTRA_ARGS = "--exit-node=100.110.81.102 --accept-routes --exit-node-allow-lan-access --accept-dns=false";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_OUTBOUND_HTTP_PROXY_LISTEN = ":8118";
        TS_USERSPACE = "false";
      };
      environmentFiles = [ config.sops.secrets."media".path ];
      volumes = [
        "${d}/config/tailscale:/var/lib/tailscale"
        "${resolvConf}:/etc/resolv.conf:ro"
        "/dev/net/tun:/dev/net/tun"
      ];
      ports = [
        "127.0.0.1:8080:8080"
        "127.0.0.1:8118:8118"
        "6881:6881"
        "6881:6881/udp"
      ];
      extraOptions = [
        "--pull=newer"
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
        "${d}/data/downloads:/data/downloads"
        "${resolvConf}:/etc/resolv.conf:ro"
      ];
      dependsOn = [ "tailscale" ];
      extraOptions = [
        "--pull=newer"
        "--network=container:tailscale"
      ];
    };

    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      extraOptions = [ "--pull=newer" ];
      environment = {
        LOG_LEVEL = "info";
        TZ = "Asia/Kolkata";
      };
    };

    seerr = {
      image = "ghcr.io/seerr-team/seerr:latest";
      extraOptions = [ "--pull=newer" ];
      environment = linuxserverEnv;
      volumes = [ "${d}/config/seerr:/app/config" ];
      ports = [ "127.0.0.1:5055:5055" ];
    };
  };

  systemd.services.podman-flaresolverr.serviceConfig.MemoryHigh = "4G";
}
