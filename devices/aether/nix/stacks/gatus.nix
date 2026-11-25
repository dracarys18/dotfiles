{
  config,
  lib,
  pkgs,
  ...
}:

let
  d = "/var/lib/stacks/gatus";

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
    "Z ${d}/data 0700 gatus gatus -"
  ];

  sops.secrets."gatus".restartUnits = [ "gatus.service" ];

  sops.templates."gatus-postgres.env" = {
    restartUnits = [ "gatus.service" ];
    content = ''
      postgres_dsn=postgres://gatus:${config.sops.placeholder."postgres-apps/gatus_password"}@127.0.0.1:5432/gatus?sslmode=disable
    '';
  };

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
      EnvironmentFile = [
        config.sops.secrets."gatus".path
        config.sops.templates."gatus-postgres.env".path
      ];
      WorkingDirectory = d;
      Restart = "always";
      RestartSec = 5;
      MemoryHigh = "256M";
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      CapabilityBoundingSet = [ "" ];
      AmbientCapabilities = [ ];
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      ReadWritePaths = [ "${d}/data" ];
    };
  };
}
