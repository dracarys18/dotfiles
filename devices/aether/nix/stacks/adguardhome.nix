{
  config,
  pkgs,
  ...
}:

let
  d = "/var/lib/stacks/adguardhome";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/conf 0700 root root -"
    "d ${d}/work 0700 root root -"
  ];

  sops.secrets."adguardhome/password_hash" = {
    sopsFile = ../secrets/adguardhome.yaml;
    key = "password_hash";
    mode = "0400";
    restartUnits = [
      "adguardhome-config.service"
      "podman-adguardhome.service"
    ];
  };


  security.pki.certificateFiles = [ ./adguardhome/dot-ca.pem ];

  sops.secrets."adguardhome/tls_cert" = {
    sopsFile = ../secrets/adguardhome.yaml;
    key = "tls_cert";
    mode = "0400";
    restartUnits = [
      "adguardhome-config.service"
      "podman-adguardhome.service"
    ];
  };

  sops.secrets."adguardhome/tls_key" = {
    sopsFile = ../secrets/adguardhome.yaml;
    key = "tls_key";
    mode = "0400";
    restartUnits = [
      "adguardhome-config.service"
      "podman-adguardhome.service"
    ];
  };

  systemd.services.adguardhome-config = {
    wantedBy = [ "multi-user.target" ];
    requiredBy = [ "podman-adguardhome.service" ];
    before = [ "podman-adguardhome.service" ];
    partOf = [ "podman-adguardhome.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu
      ${pkgs.gawk}/bin/awk \
        -v sec=${config.sops.secrets."adguardhome/password_hash".path} '
          BEGIN { while ((getline line < sec) > 0) hash = hash line; close(sec) }
          { gsub(/@ADGUARD_PASSWORD_HASH@/, hash); print }
        ' ${./adguardhome/AdGuardHome.yaml} > ${d}/conf/AdGuardHome.yaml.new
      ${pkgs.coreutils}/bin/chmod 0600 ${d}/conf/AdGuardHome.yaml.new
      ${pkgs.coreutils}/bin/mv ${d}/conf/AdGuardHome.yaml.new ${d}/conf/AdGuardHome.yaml

      ${pkgs.coreutils}/bin/install -D -m 0400 ${config.sops.secrets."adguardhome/tls_cert".path} ${d}/conf/tls/tls.crt
      ${pkgs.coreutils}/bin/install -D -m 0400 ${config.sops.secrets."adguardhome/tls_key".path} ${d}/conf/tls/tls.key
    '';
  };

  virtualisation.oci-containers.containers = {
    adguardhome = {
      image = "adguard/adguardhome:latest";
      volumes = [
        "${d}/conf:/opt/adguardhome/conf"
        "${d}/work:/opt/adguardhome/work"
      ];
      extraOptions = [
        "--pull=newer"
        "--network=host"
      ];
    };
  };

  systemd.services.podman-adguardhome = {
    restartTriggers = [ ./adguardhome/AdGuardHome.yaml ];
    after = [ "tailscaled.service" ];
  };

  systemd.services.adguardhome-resolver-pin = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "podman-adguardhome.service" ];
    after = [ "podman-adguardhome.service" ];
    partOf = [ "podman-adguardhome.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 60;
    };
    script = ''
      set -eu
      until ${pkgs.openssl}/bin/openssl s_client \
        -connect 127.0.0.1:853 \
        -servername adguard.aether.internal \
        -CAfile ${./adguardhome/dot-ca.pem} \
        -verify_return_error \
        </dev/null 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'Verify return code: 0 (ok)'; do
        sleep 1
      done
      ${config.systemd.package}/bin/systemctl restart systemd-resolved.service
    '';
  };
}
