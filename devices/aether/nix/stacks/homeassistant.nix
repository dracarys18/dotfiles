# ~/Projects/homeassistant — both services need the host network
{ config, pkgs, ... }:

let
  d = "/var/lib/stacks/homeassistant";

  configuration = pkgs.writeText "configuration.yaml" ''
    homeassistant:
      external_url: "https://has.karthihegde.dev"
      internal_url: "https://has.karthihegde.dev"

    frontend:
      themes: !include_dir_merge_named themes

    sun:
    person:
    zone:

    recorder:
      db_url: !env_var RECORDER_DB_URL
      purge_keep_days: 5
      commit_interval: 30

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
    "d ${d}/matter-data 0755 root root -"
  ];

  sops.templates."homeassistant.env" = {
    restartUnits = [ "podman-homeassistant.service" ];
    content = ''
      RECORDER_DB_URL=postgresql://homeassistant:${config.sops.placeholder."postgres-apps/homeassistant_password"}@127.0.0.1:5432/homeassistant
    '';
  };

  virtualisation.oci-containers.containers = {
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      environment.TZ = "Asia/Kolkata";
      environmentFiles = [ config.sops.templates."homeassistant.env".path ];
      volumes = [
        "${d}/config:/config"
        "${configuration}:/config/configuration.yaml:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };

    matter-server = {
      image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
      volumes = [
        "${d}/matter-data:/data"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--network=host"
        "--security-opt=apparmor=unconfined"
      ];
    };
  };
}
