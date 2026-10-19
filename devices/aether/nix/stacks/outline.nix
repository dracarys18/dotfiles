# ~/Projects/outline — compose used one `stack.env` for all three services
{ config, pkgs, ... }:

let
  d = "/var/lib/stacks/outline";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/storage 0755 root root -"
    # the redis config is a few lines; keep it out of the store so it stays
    # editable like the compose file was
    "f ${d}/redis.conf 0644 root root - appendonly yes"
  ];

  networking.firewall.allowedTCPPorts = [ 3010 ];

  virtualisation.oci-containers.containers = {
    outline = {
      image = "docker.getoutline.com/outlinewiki/outline:latest";
      environmentFiles = [ config.sops.secrets."outline".path ];
      volumes = [ "${d}/storage:/var/lib/outline/data" ];
      ports = [ "3010:3000" ];
      dependsOn = [
        "postgres"
        "redis"
      ];
    };

    redis = {
      image = "redis";
      environmentFiles = [ config.sops.secrets."outline".path ];
      volumes = [ "${d}/redis.conf:/redis.conf" ];
      cmd = [
        "redis-server"
        "/redis.conf"
      ];
    };

    postgres = {
      image = "postgres:16";
      environmentFiles = [ config.sops.secrets."outline".path ];
      environment = {
        POSTGRES_DB = "outline";
      };
      volumes = [ "${d}/pgdata:/var/lib/postgresql/data" ];
    };
  };
}
