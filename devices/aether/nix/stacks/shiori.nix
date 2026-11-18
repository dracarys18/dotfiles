{ config, ... }:

let
  d = "/var/lib/stacks/shiori";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0700 1000 1000 -"
  ];

  sops.templates."shiori-postgres.env" = {
    restartUnits = [ "podman-shiori.service" ];
    content = ''
      SHIORI_DATABASE_URL=postgres://shiori:${config.sops.placeholder."postgres-apps/shiori_password"}@postgres:5432/shiori?sslmode=disable
    '';
  };

  virtualisation.oci-containers.containers.shiori = {
    image = "ghcr.io/go-shiori/shiori:latest";
    extraOptions = [ "--pull=newer" ];
    dependsOn = [ "postgres" ];
    environment = {
      TZ = "Asia/Kolkata";
      SHIORI_DIR = "/data";
      SHIORI_SSO_PROXY_AUTH_ENABLED = "true";
      SHIORI_SSO_PROXY_AUTH_HEADER_NAME = "Remote-User";
      SHIORI_SSO_PROXY_AUTH_TRUSTED = "127.0.0.1/32,10.88.0.1/32";
    };
    environmentFiles = [
      config.sops.secrets."shiori".path
      config.sops.templates."shiori-postgres.env".path
    ];
    volumes = [ "${d}/data:/data" ];
    ports = [ "127.0.0.1:8095:8080" ];
  };

  systemd.services.podman-shiori.serviceConfig.MemoryHigh = "512M";
}
