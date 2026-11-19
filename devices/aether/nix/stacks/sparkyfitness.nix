{ config, ... }:

let
  d = "/var/lib/stacks/sparkyfitness";
  serverPort = 3010;
  frontendPort = 3670;

  fromFile = key: {
    sopsFile = ../secrets/sparkyfitness.yaml;
    inherit key;
    mode = "0400";
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/uploads 0755 1000 1000 -"
    "d ${d}/backups 0755 1000 1000 -"
    "d ${d}/temp 0755 1000 1000 -"
  ];

  sops.secrets = {
    "sparkyfitness/app_db_password" = fromFile "app_db_password";
    "sparkyfitness/api_encryption_key" = fromFile "api_encryption_key";
    "sparkyfitness/better_auth_secret" = fromFile "better_auth_secret";
    "sparkyfitness/deepseek_api_key" = fromFile "deepseek_api_key";
  };

  sops.templates."sparkyfitness.env" = {
    restartUnits = [ "podman-sparkyfitness-server.service" ];
    content = ''
      SPARKY_FITNESS_DB_PASSWORD=${config.sops.placeholder."postgres-apps/sparky_password"}
      SPARKY_FITNESS_APP_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/app_db_password"}
      SPARKY_FITNESS_API_ENCRYPTION_KEY=${config.sops.placeholder."sparkyfitness/api_encryption_key"}
      BETTER_AUTH_SECRET=${config.sops.placeholder."sparkyfitness/better_auth_secret"}
      SPARKY_FITNESS_OIDC_AUTH_ENABLED=true
      SPARKY_FITNESS_OIDC_ISSUER_URL=https://auth.karthihegde.dev
      SPARKY_FITNESS_OIDC_CLIENT_ID=sparkyfitness
      SPARKY_FITNESS_OIDC_CLIENT_SECRET=${config.sops.placeholder."authelia/oidc_sparkyfitness_secret"}
      SPARKY_FITNESS_OIDC_PROVIDER_SLUG=sparkyfitness
      SPARKY_FITNESS_OIDC_PROVIDER_NAME=Authelia
      SPARKY_FITNESS_OIDC_SCOPE=openid email profile
      SPARKY_FITNESS_OIDC_AUTO_REGISTER=true
      DEEPSEEK_API_KEY=${config.sops.placeholder."sparkyfitness/deepseek_api_key"}
    '';
  };

  virtualisation.oci-containers.containers = {
    sparkyfitness-server = {
      image = "codewithcj/sparkyfitness_server@sha256:2f064604c2034fa5953cb3e17651aad32e8a9f8362895500cd5d188376215b3a";
      dependsOn = [ "postgres" ];
      environment = {
        SPARKY_FITNESS_DB_HOST = "postgres";
        SPARKY_FITNESS_DB_PORT = "5432";
        SPARKY_FITNESS_DB_NAME = "sparkyfitness_db";
        SPARKY_FITNESS_DB_USER = "sparky";
        SPARKY_FITNESS_APP_DB_USER = "sparky_app";
        SPARKY_FITNESS_FRONTEND_URL = "https://fit.karthihegde.dev";
        SPARKY_FITNESS_SERVER_PORT = toString serverPort;
        SPARKY_FITNESS_DISABLE_SIGNUP = "true";
        SPARKY_FITNESS_ADMIN_EMAIL = "karthihegde@karthihegde.dev";
        SPARKY_FITNESS_LOG_LEVEL = "ERROR";
        SPARKY_FITNESS_CUSTOM_UPLOADS_DIRECTORY = "/app/uploads";
        SPARKY_FITNESS_CUSTOM_BACKUP_DIRECTORY = "/data/backups";
        SPARKY_FITNESS_CUSTOM_TEMP_DIRECTORY = "/data/temp";
        NODE_ENV = "production";
        TZ = "Asia/Kolkata";
      };
      environmentFiles = [ config.sops.templates."sparkyfitness.env".path ];
      volumes = [
        "${d}/uploads:/app/uploads"
        "${d}/backups:/data/backups"
        "${d}/temp:/data/temp"
        "${./sparkyfitness/foodPhotoEstimationService.ts}:/app/SparkyFitnessServer/services/foodPhotoEstimationService.ts:ro"
      ];
    };

    sparkyfitness = {
      image = "codewithcj/sparkyfitness:latest";
      dependsOn = [ "sparkyfitness-server" ];
      environment = {
        SPARKY_FITNESS_FRONTEND_URL = "https://fit.karthihegde.dev";
        SPARKY_FITNESS_SERVER_HOST = "sparkyfitness-server";
        SPARKY_FITNESS_SERVER_PORT = toString serverPort;
        PUID = "1000";
        GUID = "1000";
      };
      ports = [ "127.0.0.1:${toString frontendPort}:80" ];
    };
  };

}
