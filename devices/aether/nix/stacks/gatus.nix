{
  config,
  ...
}:

let
  d = "/var/lib/stacks/gatus";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0700 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.gatus = {
    image = "ghcr.io/twin/gatus:stable";
    extraOptions = [ "--pull=newer" ];
    environment = {
      TZ = "Asia/Kolkata";
      GATUS_CONFIG_PATH = "/config/config.yaml";
    };
    environmentFiles = [ config.sops.secrets."gatus".path ];
    volumes = [
      "${./gatus/config.yaml}:/config/config.yaml:ro"
      "${d}/data:/data"
    ];
    ports = [ "127.0.0.1:8390:8080" ];
  };

  systemd.services.podman-gatus.serviceConfig.MemoryHigh = "256M";
}
