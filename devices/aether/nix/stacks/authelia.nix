# Authelia config and users are checked in (./authelia/configuration.yml,
# users rendered below); only sessions/2FA live in the sqlite volume.
{ config, lib, ... }:

let
  d = "/var/lib/stacks/authelia";

  # add a user: put the argon2 hash in sops under users.<name>, then list it here
  users = [ "karthihegde" ];
  displayNames = {
    karthihegde = "Karthikey Hegde";
  };
  emails = {
    karthihegde = "karthihegde@karthihegde.dev";
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
  ];

  sops.secrets =
    {
      "authelia/session_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "session_secret";
        mode = "0400";
      };
      "authelia/storage_encryption_key" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "storage_encryption_key";
        mode = "0400";
      };
      "authelia/jwt_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "jwt_secret";
        mode = "0400";
      };
      "authelia/oidc_hmac_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "oidc_hmac_secret";
        mode = "0400";
      };
      "authelia/oidc_issuer_private_key" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "oidc_issuer_private_key";
        mode = "0400";
      };
      "authelia/karakeep_client_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "karakeep_client_secret";
        mode = "0400";
      };
    }
    // lib.genAttrs (map (u: "authelia/user-${u}") users) (n: {
      sopsFile = ../secrets/authelia.yaml;
      key = "user_${lib.removePrefix "authelia/user-" n}";
      mode = "0400";
    });

  sops.templates."authelia-configuration.yml" = {
    content = builtins.replaceStrings
      [
        "@SESSION_SECRET@"
        "@STORAGE_ENCRYPTION_KEY@"
        "@JWT_SECRET@"
        "@OIDC_HMAC_SECRET@"
        "@KARAKEEP_CLIENT_SECRET@"
        "@OIDC_ISSUER_PRIVATE_KEY@"
      ]
      [
        config.sops.placeholder."authelia/session_secret"
        config.sops.placeholder."authelia/storage_encryption_key"
        config.sops.placeholder."authelia/jwt_secret"
        config.sops.placeholder."authelia/oidc_hmac_secret"
        config.sops.placeholder."authelia/karakeep_client_secret"
        config.sops.placeholder."authelia/oidc_issuer_private_key"
      ]
      (builtins.readFile ./authelia/configuration.yml);
  };

  sops.templates."authelia-users.yml".content =
    "users:\n"
    + lib.concatMapStringsSep "\n"
      (u:
        "  ${u}:\n"
        + "    displayname: '${displayNames.${u}}'\n"
        + "    password: '${config.sops.placeholder."authelia/user-${u}"}'\n"
        + "    email: '${emails.${u}}'\n"
        + "    groups:\n"
        + "      - admins")
      users
    + "\n";

  virtualisation.oci-containers.containers.authelia = {
    image = "ghcr.io/authelia/authelia:latest";
    extraOptions = [ "--pull=newer" ];
    environment.TZ = "Asia/Kolkata";
    volumes = [
      "${d}/config:/config"
      "${config.sops.templates."authelia-configuration.yml".path}:/config/configuration.yml:ro"
      "${config.sops.templates."authelia-users.yml".path}:/config/users_database.yml:ro"
    ];
    ports = [ "127.0.0.1:9091:9091" ];
  };
}
