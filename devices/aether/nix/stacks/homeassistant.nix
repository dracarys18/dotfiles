{ config, pkgs, ... }:

let
  d = "/var/lib/stacks/homeassistant";

  pywizlight = pkgs.runCommand "pywizlight-0.6.3-signed" { } ''
    mkdir -p $out
    tar xzf ${pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/p/pywizlight/pywizlight-0.6.3.tar.gz";
      hash = "sha256-ddobuuMhzVhlaTPox/oDXQywGSbqb/OT5dXoMqSPnYY=";
    }} --strip-components=1 -C $out
    patch -d $out -p1 < ${./homeassistant/pywizlight-signing.patch}
  '';

  configuration = pkgs.writeText "configuration.yaml" ''
    homeassistant:
      external_url: "https://has.${config.homelab.domain}"
      internal_url: "https://has.${config.homelab.domain}"

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
          - light.wiz_rgbw_tunable_74ba34
          - light.wiz_rgbw_tunable_fcb326

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

    rest:
      - resource: "https://api.ipify.org?format=json"
        scan_interval: 600
        sensor:
          - name: Public IP
            value_template: "{{ value_json.ip }}"

    history:
    logbook:

    automation:
      - id: "1776013654348"
        alias: Good Morning
        triggers:
          - trigger: time
            at: "06:30:00"
        actions:
          - action: light.turn_on
            target:
              entity_id: light.wiz_rgbw_tunable_74ba34
            data:
              brightness_pct: 50
              effect: Warm white
          - action: light.turn_on
            target:
              entity_id: light.wiz_rgbw_tunable_fcb326
            data:
              brightness_pct: 100
              effect: Warm white
        mode: single
      - id: "1782757716769"
        alias: Good Night
        triggers:
          - trigger: time
            at: "23:00:00"
        actions:
          - action: light.turn_on
            target:
              entity_id:
                - light.wiz_rgbw_tunable_74ba34
                - light.wiz_rgbw_tunable_fcb326
            data:
              brightness_pct: 20
        mode: single

    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';
in
{
  services.caddy.virtualHosts."has.${config.homelab.domain}".extraConfig = ''
    reverse_proxy 127.0.0.1:8123 {
      header_up Host {host}
      header_up X-Real-IP {remote_host}
      header_up X-Forwarded-For {remote_host}
      header_up X-Forwarded-Proto "https"
    }
  '';

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
    "d ${d}/matter-data 0755 1000 1000 -"
    "Z ${d}/matter-data 0755 1000 1000 -"
  ];

  sops.secrets."homeassistant/udp_signing_key" = {
    sopsFile = ../secrets/homeassistant.yaml;
    key = "udp_signing_key";
    mode = "0400";
  };

  sops.templates."homeassistant.env" = {
    restartUnits = [ "podman-homeassistant.service" ];
    content = ''
      RECORDER_DB_URL=postgresql://homeassistant:${config.sops.placeholder."postgres-apps/homeassistant_password"}@127.0.0.1:5432/homeassistant
      WIZ_SIGNING_KEY=${config.sops.placeholder."homeassistant/udp_signing_key"}
    '';
  };

  virtualisation.oci-containers.containers = {
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant@sha256:493a07e8f6530fc640223f4a0a5248f20a61ca2f718bb1d31efbf08a2c5ea28f";
      environment.TZ = "Asia/Kolkata";
      environmentFiles = [ config.sops.templates."homeassistant.env".path ];
      volumes = [
        "${d}/config:/config"
        "${configuration}:/config/configuration.yaml:ro"
        "${./homeassistant/themes}:/config/themes:ro"
        "${./homeassistant/home-dash.yaml}:/config/home-dash.yaml:ro"
        "${pywizlight}/pywizlight:/usr/local/lib/python3.14/site-packages/pywizlight:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };

    matter-server = {
      image = "ghcr.io/matter-js/matterjs-server@sha256:27d68110ba213d35e2f10513be9d379acad4d3e809356df4e00c0e9c4c9e48d7";
      environment = {
        STORAGE_PATH = "/data";
        PRIMARY_INTERFACE = "lan0";
      };
      volumes = [
        "${d}/matter-data:/data"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--network=host"
      ];
    };
  };
}
