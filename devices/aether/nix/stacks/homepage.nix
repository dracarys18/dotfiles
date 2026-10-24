# ~/Projects/homepage — reads the docker-compatible podman socket
let
  d = "/var/lib/stacks/homepage";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config ${d}/assets 0755 root root -"
  ];

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "home.karthihegde.dev";
      PUID = "1000";
      PGID = "1000";
    };
    volumes = [
      "${d}/config:/app/config"
      "${d}/assets:/app/public/images"
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];
    ports = [ "127.0.0.1:3669:3000" ];
  };
}
