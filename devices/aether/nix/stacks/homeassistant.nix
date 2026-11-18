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

    lovelace:
      dashboards:
        home-dash:
          mode: yaml
          title: Home
          icon: mdi:home-analytics
          show_in_sidebar: true
          filename: home-dash.yaml

    light:
      - platform: group
        name: All lights
        unique_id: all_lights
        entities:
          - light.wiz_rgbw_tunable_0d4612
          - light.wiz_rgbw_tunable_6507e4

    sun:
    person:
    zone:

    recorder:
      db_url: !env_var RECORDER_DB_URL
      purge_keep_days: 5
      commit_interval: 30

    sql:
      - name: Electricity this month
        db_url: !env_var RECORDER_DB_URL
        column: kwh
        unit_of_measurement: kWh
        query: >
          select round(coalesce(a.sum, 0)::numeric - coalesce(b.sum, 0)::numeric, 2) as kwh
          from (select s.sum from statistics s join statistics_meta m on m.id = s.metadata_id
                where m.statistic_id = 'sensor.smart_wi_fi_plug_energy'
                order by s.start_ts desc limit 1) a
          cross join (select s.sum from statistics s join statistics_meta m on m.id = s.metadata_id
                where m.statistic_id = 'sensor.smart_wi_fi_plug_energy'
                  and s.start_ts < extract(epoch from (date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata'))
                order by s.start_ts desc limit 1) b

    history:
    logbook:

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
    "d ${d}/matter-data 0755 1000 1000 -"
    "Z ${d}/matter-data 0755 1000 1000 -"
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
        "${./homeassistant/themes}:/config/themes:ro"
        "${./homeassistant/home-dash.yaml}:/config/home-dash.yaml:ro"
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
      image = "ghcr.io/matter-js/matterjs-server:stable";
      environment = {
        STORAGE_PATH = "/data";
        PRIMARY_INTERFACE = "lan0";
      };
      volumes = [
        "${d}/matter-data:/data"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=host"
      ];
    };
  };
}
