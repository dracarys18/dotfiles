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
  services.caddy.virtualHosts."media.${config.homelab.domain}".extraConfig = ''
    @plainRoot {
      path /
      not header Referer */sso/OIDC/Callback/*
    }
    redir @plainRoot /sso/OIDC/Start/authelia 302
    reverse_proxy 127.0.0.1:8096
  '';

  services.caddy.virtualHosts."requests.${config.homelab.domain}".extraConfig = ''
    import auth
    reverse_proxy 127.0.0.1:5055 {
      header_up Cookie "connect.sid={env.SEERR_SESSION_COOKIE}"
    }
  '';

  services.caddy.virtualHosts."radarr.${config.homelab.domain}".extraConfig = "import gated 7878";
  services.caddy.virtualHosts."sonarr.${config.homelab.domain}".extraConfig = "import gated 8989";
  services.caddy.virtualHosts."prowlarr.${config.homelab.domain}".extraConfig = "import gated 9696";
  services.caddy.virtualHosts."torrent.${config.homelab.domain}".extraConfig = "import gated 8080";

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

  sops.templates."seerr-db.env" = {
    restartUnits = [ "podman-seerr.service" ];
    content = ''
      DB_PASS=${config.sops.placeholder."postgres-apps/seerr_password"}
    '';
  };

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
      image = "lscr.io/linuxserver/jellyfin@sha256:b10044530553b2506f06279bf0b5223f9534f434f87a277da4b8fa8ac386cb58";
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
      image = "lscr.io/linuxserver/radarr@sha256:b7dc6ad52f645a8db3970b32218b2d5d133cab8b8ad66f2e7f73fe2ce382f002";
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/radarr:/config"
        "${d}/data:/data"
      ];
      ports = [ "127.0.0.1:7878:7878" ];
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr@sha256:c8c4a3dcb49e1bd3ee19cf33e128837fdd6615e7a6b69cf02326133e193e4c29";
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/sonarr:/config"
        "${d}/data:/data"
      ];
      ports = [ "127.0.0.1:8989:8989" ];
    };

    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr@sha256:2806c9b763810589c42157730d547c293639e55c7610e9f5069314854639ec48";
      environment = linuxserverEnv;
      volumes = [ "${d}/config/prowlarr:/config" ];
      ports = [ "127.0.0.1:9696:9696" ];
    };

    tailscale = {
      image = "tailscale/tailscale@sha256:72c1e19e0aedca96b8533bbb0b4368564410ff20b17e53b804eb6c1f04a31be4";
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
        "--hostname=qbittorrent-vpn"
        "--dns=193.138.218.74"
        "--network=podman:alias=vpn-tunnel"
        "--cap-add=net_admin"
        "--cap-add=sys_module"
      ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent@sha256:1fa2f9692501f27ce51c4fffd771d63ec38f1163cb648941c324344b7c5a3915";
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
        "--network=container:tailscale"
      ];
    };

    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr@sha256:4ad0ed7de64622f9823594bf7bc237149158fca881f875aafbdd8456f6467134";
      environment = {
        LOG_LEVEL = "info";
        TZ = "Asia/Kolkata";
      };
    };

    seerr = {
      image = "ghcr.io/seerr-team/seerr@sha256:aadee014b40e28cf9aa4928bc9d1183a6eb08f8c44d543cddc9efdcb16549be2";
      dependsOn = [ "postgres" ];
      environment = linuxserverEnv // {
        DB_TYPE = "postgres";
        DB_HOST = "postgres";
        DB_PORT = "5432";
        DB_USER = "seerr";
        DB_NAME = "seerr";
      };
      environmentFiles = [ config.sops.templates."seerr-db.env".path ];
      volumes = [ "${d}/config/seerr:/app/config" ];
      ports = [ "127.0.0.1:5055:5055" ];
    };
  };

  systemd.services.podman-flaresolverr.serviceConfig.MemoryHigh = "4G";
}
