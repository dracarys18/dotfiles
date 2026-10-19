# ~/Projects/immich
#
# Two deliberate changes from the compose file: the ML image drops the `-cuda`
# tag (no NVIDIA card), and DB_HOSTNAME/REDIS_HOSTNAME are set explicitly —
# compose also registered the service names `database`/`redis` as network
# aliases, podman only knows the container names.
{
  config,
  ...
}:

let
  d = "/var/lib/stacks/immich";
  version = "release";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/upload 0755 root root -"
    "d ${d}/pgdata 0755 root root -"
    "d ${d}/model-cache 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 2283 ];

  virtualisation.oci-containers.containers = {
    immich_server = {
      image = "ghcr.io/immich-app/immich-server:${version}";
      environment = {
        DB_HOSTNAME = "immich_postgres";
        REDIS_HOSTNAME = "immich_redis";
      };
      environmentFiles = [ config.sops.secrets."immich".path ];
      volumes = [
        "${d}/upload:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ "2283:2283" ];
      dependsOn = [
        "immich_redis"
        "immich_postgres"
      ];
    };

    immich_machine_learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}";
      environmentFiles = [ config.sops.secrets."immich".path ];
      volumes = [ "${d}/model-cache:/cache" ];
    };

    immich_redis = {
      image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
    };

    immich_postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
      environment = {
        DB_STORAGE_TYPE = "HDD";
      };
      environmentFiles = [ config.sops.secrets."immich".path ];
      volumes = [ "${d}/pgdata:/var/lib/postgresql/data" ];
    };
  };
}
