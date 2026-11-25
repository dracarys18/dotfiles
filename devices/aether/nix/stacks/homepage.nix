{ config, ... }:

let
  d = "/var/lib/stacks/homepage";
  cfg = ./homepage;
in
{
  services.caddy.virtualHosts."home.${config.homelab.domain}".extraConfig = "import proxy 3669";

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/logs 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage@sha256:019d8f063a7299e7c1c51ee4a70b692291809af3244894fbec2c2ac7d1f71b18";
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "home.${config.homelab.domain}";
      PUID = "1000";
      PGID = "1000";
    };
    environmentFiles = [ config.sops.secrets."homepage".path ];
    volumes = [
      "${cfg}/services.yaml:/app/config/services.yaml:ro"
      "${cfg}/settings.yaml:/app/config/settings.yaml:ro"
      "${cfg}/widgets.yaml:/app/config/widgets.yaml:ro"
      "${cfg}/bookmarks.yaml:/app/config/bookmarks.yaml:ro"
      "${cfg}/custom.css:/app/config/custom.css:ro"
      "${cfg}/custom.js:/app/config/custom.js:ro"
      "${./homepage-cartero.png}:/app/public/images/cartero.png:ro"
      "${d}/logs:/app/config/logs"
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];
    ports = [ "127.0.0.1:3669:3000" ];
  };
}
