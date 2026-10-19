# ~/Projects/karakeep — the web container's compose overrides named the
# services `meilisearch`/`chrome`; podman only resolves the container names,
# so they are spelled out here.
{ config, ... }:

let
  d = "/var/lib/stacks/karakeep";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data ${d}/meili_data 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 3069 ];

  virtualisation.oci-containers.containers = {
    karakeep-web-1 = {
      image = "ghcr.io/karakeep-app/karakeep:release";
      environment = {
        MEILI_ADDR = "http://karakeep-meilisearch-1:7700";
        BROWSER_WEB_URL = "http://karakeep-chrome-1:9222";
        DATA_DIR = "/data";
      };
      environmentFiles = [ config.sops.secrets."karakeep".path ];
      volumes = [ "${d}/data:/data" ];
      ports = [ "3069:3000" ];
      dependsOn = [
        "karakeep-meilisearch-1"
        "karakeep-chrome-1"
      ];
    };

    karakeep-meilisearch-1 = {
      image = "getmeili/meilisearch:v1.13.3";
      environmentFiles = [ config.sops.secrets."karakeep".path ];
      volumes = [ "${d}/meili_data:/meili_data" ];
    };

    karakeep-chrome-1 = {
      image = "gcr.io/zenika-hub/alpine-chrome:latest";
      cmd = [
        "--no-sandbox"
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--remote-debugging-address=0.0.0.0"
        "--remote-debugging-port=9222"
        "--hide-scrollbars"
      ];
    };
  };
}
