{
  config,
  lib,
  pkgs,
  ...
}:

let
  d = "/var/lib/stacks/gatus";

  # the dashboard gains one script: it totals the 30d uptime of every endpoint
  # under the heading and turns each card's hostname into a link. patching the
  # checked-in web/static (no npm step: the bundle is committed upstream) keeps
  # caddy out of it — no response rewriting, no plugin, nothing to keep in sync
  # at the proxy.
  gatus = pkgs.gatus.overrideAttrs (old: {
    postPatch = ''
      substituteInPlace web/static/index.html \
        --replace '</body>' '<script src="/uptime.js" defer></script></body>'
      cp ${./gatus/uptime.js} web/static/uptime.js
    '';
  });
in
{
  users.groups.gatus = { };

  users.users.gatus = {
    isSystemUser = true;
    group = "gatus";
  };

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0700 gatus gatus -"
    # the db was written by root while gatus ran as a container; Z takes it over
    "Z ${d}/data 0700 gatus gatus -"
  ];

  sops.secrets."gatus".restartUnits = [ "gatus.service" ];

  systemd.services.gatus = {
    description = "Gatus health dashboard";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    after = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    environment = {
      GATUS_CONFIG_PATH = "${./gatus/config.yaml}";
      TZ = "Asia/Kolkata";
    };
    serviceConfig = {
      ExecStart = lib.getExe gatus;
      User = "gatus";
      Group = "gatus";
      EnvironmentFile = config.sops.secrets."gatus".path;
      WorkingDirectory = d;
      Restart = "always";
      RestartSec = 5;
      MemoryHigh = "256M";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "${d}/data" ];
    };
  };
}
