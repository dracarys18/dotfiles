# ~/Projects/searchxng — the compose file published ${SEARXNG_PORT:-8080},
# which was 6996 on the old box
{ config, ... }:

let
  d = "/var/lib/stacks/searchxng";
  port = "6996";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/core-config 0755 root root -"
    "d ${d}/core-data 0755 root root -"
    "d ${d}/valkey-data 0755 root root -"
  ];

  virtualisation.oci-containers.containers = {
    searxng-core = {
      image = "docker.io/searxng/searxng:latest";
      environmentFiles = [ config.sops.secrets."searchxng".path ];
      volumes = [
        "${d}/core-config:/etc/searxng"
        "${d}/core-data:/var/cache/searxng"
      ];
      ports = [ "127.0.0.1:${port}:${port}" ];
      # settings.yml is part of the live config on archmaestro
      autoStart = false;
    };

    searxng-valkey = {
      image = "docker.io/valkey/valkey:9-alpine";
      cmd = [
        "valkey-server"
        "--save"
        "30"
        "1"
        "--loglevel"
        "warning"
      ];
      volumes = [ "${d}/valkey-data:/data" ];
    };
  };
}
