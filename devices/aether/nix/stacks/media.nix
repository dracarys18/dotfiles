# ~/Projects/mediastack — media server, *arr apps and the VPN sidecar. The
# tailscale container owns the network namespace qbittorrent and privoxy run
# in, exactly like `network_mode: service:tailscale`.
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
  # the sidecar runs with an exit node, whose default route swallows the podman
  # gateway (10.88.0.1), so podman's internal resolver is unreachable inside it
  # and DNS dies. A literal resolv.conf pointing at a public resolver works,
  # because that traffic goes through the tunnel like everything else.
  # Generated here rather than kept in the state dir: a runtime path for a bind
  # mount that is missing gets created as a *directory* by preStart, which is
  # how this broke the first time.
  resolvConf = pkgs.writeText "mediastack-resolv.conf" ''
    nameserver 1.1.1.1
    nameserver 9.9.9.9
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
    # the seerr image runs as node:node (uid 1000) with no root startup step to
    # fix ownership, unlike the linuxserver images, so the dir must be owned
    # correctly before it boots
    "d ${d}/config/seerr 0775 1000 1000 -"
    "d ${d}/config/tailscale 0755 root root -"
    "d ${d}/data 0755 root root -"
    "d ${d}/data/media 0755 root root -"
    "d ${d}/data/media/movies 0775 1000 1000 -"
    "d ${d}/data/media/tv 0775 1000 1000 -"
    # the containers drop to PUID 1000, so qbittorrent cannot write here
    # otherwise, and the *arr apps could not delete an imported torrent either
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

  # Downloads and the library are one tree, /data, mounted at the same path in
  # every container. Radarr and Sonarr hardlink an imported download into
  # /data/media instead of copying it, so a library file and its still-seeding
  # torrent are the same inode and cost one copy of the bytes. That is what
  # lets qbittorrent delete its own path once a seeding ratio is met without
  # the library losing anything.
  #
  # 6881 stays on every interface (peers connect in); 8118 is only used from
  # the podman network and the host, so it is loopback. Both are inside the
  # tailscale sidecar's namespace; firewall.nix opens 6881 to the internet
  # along with tailscale's own port

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
      image = "lscr.io/linuxserver/sonarr:latest";
      extraOptions = [ "--pull=newer" ];
      environment = linuxserverEnv;
      volumes = [
        "${d}/config/sonarr:/config"
        # same single mount as radarr: downloads and media must share one
        # filesystem so imports can hardlink instead of copying
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
        # Mullvad Hong Kong. This is the one tailnet address that has to stay
        # an IP: the image runs `tailscale up` before the netmap is loaded, and
        # the CLI refuses to resolve an exit-node name at that point ("cannot
        # resolve exit node by hostname while Tailscale is starting up"), which
        # leaves this unit restarting forever. The Singapore server this used
        # to point at shows as "selected but offline".
        TS_EXTRA_ARGS = "--exit-node=100.127.156.108 --accept-routes --exit-node-allow-lan-access --accept-dns=false";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_OUTBOUND_HTTP_PROXY_LISTEN = ":8118";
        TS_USERSPACE = "true";
      };
      # TS_AUTHKEY comes from sops: devices/aether/nix/secrets/media.env
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
        # same path as the *arr apps see, so no remote path mapping is needed
        "${d}/data/downloads:/data/downloads"
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

    # Seerr (the Jellyseerr/Overseerr successor) migrates the old data on its
    # first start, so the config dir is a copy of config/jellyseerr taken before
    # the first boot — see the copy step in the migration note in the repo log.
    # Same port, so caddy.nix needs no change.
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
