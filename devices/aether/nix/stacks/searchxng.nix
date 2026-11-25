{ config, ... }:

let
  d = "/var/lib/stacks/searchxng";
  port = "6996";
in
{
  services.caddy.virtualHosts."search.${config.homelab.domain}".extraConfig = "import proxy ${port}";

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/core-config 0755 root root -"
    "d ${d}/core-data 0755 root root -"
    "d ${d}/valkey-data 0755 root root -"
  ];

  virtualisation.oci-containers.containers = {
    searxng-core = {
      image = "docker.io/searxng/searxng@sha256:a7fc607aa6723f5a8982105bcc5ffba4d1b9fc7c6922a31a88d6e4cba49ef12a";
      environmentFiles = [ config.sops.secrets."searchxng".path ];
      volumes = [
        "${d}/core-config:/etc/searxng"
        "${d}/core-data:/var/cache/searxng"
      ];
      ports = [ "127.0.0.1:${port}:${port}" ];
    };

    searxng-valkey = {
      image = "docker.io/valkey/valkey@sha256:c8e2d17498838af5d91e12eb7c11220b3434a7b7131a333e3af52ad5e0b80882";
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
