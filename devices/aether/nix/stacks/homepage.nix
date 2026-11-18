# ~/Projects/homepage — reads the docker-compatible podman socket.
#
# The dashboard's own config is checked in under ./homepage and mounted out of
# the store, so a redeploy is the only way to change it. The box keeps just the
# log directory writable.
{ config, ... }:

let
  d = "/var/lib/stacks/homepage";
  cfg = ./homepage;
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/logs 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "home.karthihegde.dev";
      PUID = "1000";
      PGID = "1000";
    };
    # widget API keys ({{HOMEPAGE_VAR_*}}) come from sops, not from services.yaml
    environmentFiles = [ config.sops.secrets."homepage".path ];
    volumes = [
      "${cfg}/services.yaml:/app/config/services.yaml:ro"
      "${cfg}/settings.yaml:/app/config/settings.yaml:ro"
      "${cfg}/widgets.yaml:/app/config/widgets.yaml:ro"
      "${cfg}/bookmarks.yaml:/app/config/bookmarks.yaml:ro"
      "${cfg}/custom.css:/app/config/custom.css:ro"
      "${cfg}/custom.js:/app/config/custom.js:ro"
      # cartero's mascot, served by the dashboard out of /app/public/images
      "${./homepage-cartero.png}:/app/public/images/cartero.png:ro"
      "${d}/logs:/app/config/logs"
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];
    ports = [ "127.0.0.1:3669:3000" ];
  };
}
