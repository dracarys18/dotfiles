# ~/Projects/cartero — compose put `tunnel` and `reader` behind profiles, so
# they are declared with autoStart = false: present, started by hand when wanted.
{ config, ... }:

let
  d = "/var/lib/stacks/cartero";
  project = "/var/lib/stacks/cartero/src";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/redis ${d}/postgres ${d}/data ${project} 0755 root root -"
  ];

  virtualisation.oci-containers.containers = {
    cartero-redis = {
      image = "redis/redis-stack:latest";
      volumes = [ "${d}/redis:/data" ];
      ports = [ "127.0.0.1:6379:6379" ];
    };

    cartero-postgres = {
      image = "pgvector/pgvector:pg17";
      environment = {
        POSTGRES_USER = "cartero";
        POSTGRES_DB = "cartero";
      };
      environmentFiles = [ config.sops.secrets."cartero".path ];
      volumes = [ "${d}/postgres:/var/lib/postgresql/data" ];
      ports = [ "127.0.0.1:5432:5432" ];
    };

    cartero = {
      image = "ghcr.io/dracarys18/cartero:latest";
      environment = {
        TZ = "UTC";
        OLLAMA_HOST = "http://host.docker.internal:11434";
        CARTERO_QUEUE_PREFIX = "cartero";
      };
      environmentFiles = [ config.sops.secrets."cartero".path ];
      volumes = [
        "${project}/config.toml:/app/config.toml:ro"
        "${project}/myfeed.opml:/app/myfeed.opml:ro"
        "${project}/templates:/app/templates:ro"
        "${d}/data:/app/data"
      ];
      ports = [ "127.0.0.1:8034:8080" ];
      cmd = [
        "-config"
        "/app/config.toml"
      ];
      dependsOn = [
        "cartero-postgres"
        "cartero-redis"
      ];
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--dns=1.1.1.1"
        "--dns=8.8.8.8"
        "--dns-opt=timeout:2"
        "--dns-opt=attempts:3"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      ];
    };

    cloudflare-tunnel = {
      image = "cloudflare/cloudflared:latest";
      cmd = [
        "tunnel"
        "--no-autoupdate"
        "run"
      ];
      environmentFiles = [ config.sops.secrets."cartero".path ];
      autoStart = false;
    };

    cartero-reader = {
      image = "ghcr.io/jina-ai/reader:latest";
      autoStart = false;
      extraOptions = [
        "--memory=2g"
        "--memory-swap=2g"
        "--shm-size=1gb"
        "--cpus=2"
        "--security-opt=seccomp=unconfined"
        "--dns=1.1.1.1"
        "--dns=8.8.8.8"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      ];
    };
  };
}
