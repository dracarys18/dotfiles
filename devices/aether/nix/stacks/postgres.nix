{ config, lib, pkgs, ... }:

let
  d = "/var/lib/stacks/postgres";

  apps = [
    {
      role = "cartero";
      database = "cartero";
      password = "cartero";
      createrole = false;
      extensions = [ "vector" ];
    }
    {
      role = "sparky";
      database = "sparkyfitness_db";
      password = config.sops.placeholder."postgres-apps/sparky_password";
      createrole = true;
      runtimeRole = {
        role = "sparky_app";
        password = config.sops.placeholder."sparkyfitness/app_db_password";
      };
      extensions = [
        "pgcrypto"
        "uuid-ossp"
      ];
    }
    {
      role = "authelia";
      database = "authelia";
      password = config.sops.placeholder."postgres-apps/authelia_password";
      createrole = false;
      extensions = [ ];
    }
    {
      role = "homeassistant";
      database = "homeassistant";
      password = config.sops.placeholder."postgres-apps/homeassistant_password";
      createrole = false;
      extensions = [ ];
    }
    {
      role = "lldap";
      database = "lldap";
      password = config.sops.placeholder."postgres-apps/lldap_password";
      createrole = false;
      extensions = [ ];
    }
    {
      role = "shiori";
      database = "shiori";
      password = config.sops.placeholder."postgres-apps/shiori_password";
      createrole = false;
      extensions = [ ];
    }
    {
      role = "gatus";
      database = "gatus";
      password = config.sops.placeholder."postgres-apps/gatus_password";
      createrole = false;
      extensions = [ ];
    }
  ];

  appSql = a: ''
    DO $do$ BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${a.role}') THEN
        CREATE ROLE ${a.role} LOGIN NOSUPERUSER NOCREATEDB ${if a.createrole then "CREATEROLE" else "NOCREATEROLE"} NOINHERIT;
      END IF;
    END $do$;
    ALTER ROLE ${a.role} WITH LOGIN PASSWORD '${a.password}';
    SELECT format('CREATE DATABASE %I OWNER %I', '${a.database}', '${a.role}')
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${a.database}')\gexec
    REVOKE ALL ON DATABASE ${a.database} FROM PUBLIC;
    GRANT CONNECT, TEMPORARY ON DATABASE ${a.database} TO ${a.role};
    \connect ${a.database}
    ALTER SCHEMA public OWNER TO ${a.role};
    REVOKE ALL ON SCHEMA public FROM PUBLIC;
    GRANT USAGE, CREATE ON SCHEMA public TO ${a.role};
    ${lib.concatMapStrings (e: "CREATE EXTENSION IF NOT EXISTS \"${e}\";\n") a.extensions}
    ${runtimeSql a}
  '';

  runtimeSql = a:
    lib.optionalString (a ? runtimeRole) ''
      DO $do$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${a.runtimeRole.role}') THEN
          CREATE ROLE ${a.runtimeRole.role} LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
        END IF;
      END $do$;
      ALTER ROLE ${a.runtimeRole.role} WITH LOGIN PASSWORD '${a.runtimeRole.password}';
      GRANT CONNECT, TEMPORARY ON DATABASE ${a.database} TO ${a.runtimeRole.role};
      GRANT USAGE ON SCHEMA public TO ${a.runtimeRole.role};
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${a.runtimeRole.role};
      GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${a.runtimeRole.role};
      ALTER DEFAULT PRIVILEGES FOR ROLE ${a.role} IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${a.runtimeRole.role};
      ALTER DEFAULT PRIVILEGES FOR ROLE ${a.role} IN SCHEMA public
        GRANT USAGE, SELECT ON SEQUENCES TO ${a.runtimeRole.role};
    '';

  appsSql = config.sops.templates."postgres-apps.sql".path;
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0700 999 999 -"
  ];

  sops.secrets = {
    "postgres-apps/sparky_password" = {
      sopsFile = ../secrets/postgres-apps.yaml;
      key = "sparky_password";
      mode = "0400";
    };
    "postgres-apps/authelia_password" = {
      sopsFile = ../secrets/postgres-apps.yaml;
      key = "authelia_password";
      mode = "0400";
    };
    "postgres-apps/homeassistant_password" = {
      sopsFile = ../secrets/postgres-apps.yaml;
      key = "homeassistant_password";
      mode = "0400";
    };
    "postgres-apps/lldap_password" = {
      sopsFile = ../secrets/postgres-apps.yaml;
      key = "lldap_password";
      mode = "0400";
    };
    "postgres-apps/shiori_password" = {
      sopsFile = ../secrets/postgres-apps.yaml;
      key = "shiori_password";
      mode = "0400";
    };
    "postgres-apps/gatus_password" = {
      sopsFile = ../secrets/postgres-apps.yaml;
      key = "gatus_password";
      mode = "0400";
    };
  };

  sops.templates."postgres-apps.sql" = {
    restartUnits = [ "postgres-apps.service" ];
    mode = "0400";
    content = lib.concatMapStrings appSql apps;
  };

  systemd.services.postgres-apps = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "podman-postgres.service" ];
    after = [ "podman-postgres.service" ];
    partOf = [ "podman-postgres.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      set -eu
      until ${pkgs.podman}/bin/podman exec postgres pg_isready -U postgres -q; do sleep 2; done
      ${pkgs.podman}/bin/podman exec -i postgres psql -v ON_ERROR_STOP=1 -q -U postgres < ${appsSql}
    '';
  };

  sops.secrets."postgres".restartUnits = [ "podman-postgres.service" ];

  virtualisation.oci-containers.containers.postgres = {
    image = "pgvector/pgvector:pg17";
    extraOptions = [ ];
    environment = {
      POSTGRES_USER = "postgres";
      POSTGRES_DB = "postgres";
    };
    environmentFiles = [ config.sops.secrets."postgres".path ];
    volumes = [ "${d}/data:/var/lib/postgresql/data" ];
    ports = [ "127.0.0.1:5432:5432" ];
  };
}
