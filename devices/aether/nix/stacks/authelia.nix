{ config, lib, pkgs, ... }:

let
  d = "/var/lib/stacks/authelia";

  gatedVHosts = lib.filterAttrs (_: v: lib.hasInfix "import auth" v.extraConfig) config.services.caddy.virtualHosts;

  serviceName = domain: lib.removeSuffix ".karthihegde.dev" domain;

  groupFor = domain: if serviceName domain == "admin" then "admins" else "${serviceName domain}_users";

  serviceGroups = lib.unique (
    lib.mapAttrsToList (domain: _: groupFor domain) gatedVHosts ++ lib.attrValues oidcClients
  );

  oidcClients = {
    jellyfin = "jellyfin_users";
    sparkyfitness = "fit_users";
    radarr = "radarr_users";
    sonarr = "sonarr_users";
  };

  lanV4 =
    let
      a = lib.head config.networking.interfaces.lan0.ipv4.addresses;
    in
    "${a.address}/32";

  accessControl =
    "access_control:\n"
    + "  default_policy: deny\n"
    + "  rules:\n"
    + "    - domain: '*.karthihegde.dev'\n"
    + "      networks:\n"
    + "        - 127.0.0.1/32\n"
    + "        - 10.88.0.0/16\n"
    + "        - ${lanV4}\n"
    + "        - 100.113.199.45/32\n"
    + "        - fd7a:115c:a1e0::f52d:c72e/128\n"
    + "      policy: bypass\n"
    + lib.concatStrings (
      lib.mapAttrsToList (domain: _:
        "    - domain: '${domain}'\n"
        + "      subject:\n"
        + "        - 'group:${groupFor domain}'\n"
        + "      policy: one_factor\n")
      gatedVHosts
    );

  oidcPolicies =
    "    authorization_policies:\n"
    + lib.concatStrings (
      lib.mapAttrsToList (client: group:
        "      ${client}:\n"
        + "        default_policy: 'deny'\n"
        + "        rules:\n"
        + "          - policy: 'one_factor'\n"
        + "            subject:\n"
        + "              - 'group:${group}'\n")
      oidcClients
    );
in
{

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
    "d /var/lib/stacks/lldap 0750 lldap lldap -"
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
      "authelia/jellyfin_client_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "jellyfin_client_secret";
        mode = "0400";
      };
      "authelia/oidc_sparkyfitness_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "oidc_sparkyfitness_secret";
        mode = "0400";
      };
      "authelia/radarr_client_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "radarr_client_secret";
        mode = "0400";
      };
      "authelia/sonarr_client_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "sonarr_client_secret";
        mode = "0400";
      };
      "lldap/admin_password" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "lldap_admin_password";
        owner = "lldap";
        mode = "0400";
        restartUnits = [ "lldap.service" ];
      };
      "lldap/jwt_secret" = {
        sopsFile = ../secrets/authelia.yaml;
        key = "lldap_jwt_secret";
        owner = "lldap";
        mode = "0400";
        restartUnits = [ "lldap.service" ];
      };
    };

  systemd.services.podman-authelia.environment.AUTHELIA_CONFIG_HASH =
    builtins.hashString "sha256" config.sops.templates."authelia-configuration.yml".content;

  sops.templates."authelia-configuration.yml" = {
    restartUnits = [ "podman-authelia.service" ];
    content = builtins.replaceStrings
      [
        "@SESSION_SECRET@"
        "@STORAGE_ENCRYPTION_KEY@"
        "@JWT_SECRET@"
        "@OIDC_HMAC_SECRET@"
        "@JELLYFIN_CLIENT_SECRET@"
        "@SPARKYFITNESS_CLIENT_SECRET@"
        "@RADARR_CLIENT_SECRET@"
        "@SONARR_CLIENT_SECRET@"
        "@OIDC_ISSUER_PRIVATE_KEY@"
        "@LLDAP_PASSWORD@"
        "@STORAGE_PASSWORD@"
        "@ACCESS_CONTROL@"
        "@OIDC_POLICIES@"
      ]
      [
        config.sops.placeholder."authelia/session_secret"
        config.sops.placeholder."authelia/storage_encryption_key"
        config.sops.placeholder."authelia/jwt_secret"
        config.sops.placeholder."authelia/oidc_hmac_secret"
        config.sops.placeholder."authelia/jellyfin_client_secret"
        config.sops.placeholder."authelia/oidc_sparkyfitness_secret"
        config.sops.placeholder."authelia/radarr_client_secret"
        config.sops.placeholder."authelia/sonarr_client_secret"
        config.sops.placeholder."authelia/oidc_issuer_private_key"
        config.sops.placeholder."lldap/admin_password"
        config.sops.placeholder."postgres-apps/authelia_password"
        accessControl
        oidcPolicies
      ]
      (builtins.readFile ./authelia/configuration.yml);
  };

  virtualisation.oci-containers.containers.authelia = {
    image = "ghcr.io/authelia/authelia:latest";
    extraOptions = [
      "--pull=newer"
      "--network=host"
    ];
    environment.TZ = "Asia/Kolkata";
    volumes = [
      "${d}/config:/config"
      "${config.sops.templates."authelia-configuration.yml".path}:/config/configuration.yml:ro"
    ];
  };

  systemd.services.podman-authelia = {
    after = [ "lldap.service" ];
    wants = [ "lldap.service" ];
  };

  users.users.lldap = {
    isSystemUser = true;
    group = "lldap";
  };
  users.groups.lldap = { };

  services.lldap = {
    enable = true;
    environmentFile = config.sops.templates."lldap.env".path;
    settings = {
      ldap_base_dn = "dc=karthihegde,dc=dev";
      ldap_user_dn = "admin";
      ldap_user_email = "admin@karthihegde.dev";
      ldap_host = "127.0.0.1";
      ldap_port = 3890;
      http_host = "127.0.0.1";
      http_port = 5090;
      http_url = "https://admin.karthihegde.dev";
      ldap_user_pass_file = config.sops.secrets."lldap/admin_password".path;
      jwt_secret_file = config.sops.secrets."lldap/jwt_secret".path;
      force_ldap_user_pass_reset = "always";
    };
  };

  systemd.services.authelia-logs-prune = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman exec postgres psql -U authelia -d authelia -c \"DELETE FROM authentication_logs WHERE time < now() - interval '30 days'\"";
    };
  };

  systemd.timers.authelia-logs-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  sops.templates."lldap.env" = {
    restartUnits = [ "lldap.service" ];
    mode = "0400";
    content = ''
      LLDAP_DATABASE_URL=postgres://lldap:${config.sops.placeholder."postgres-apps/lldap_password"}@127.0.0.1:5432/lldap
    '';
  };

  systemd.services.lldap.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "lldap";
    Group = "lldap";
    StateDirectory = lib.mkForce "";
    WorkingDirectory = lib.mkForce "/var/lib/stacks/lldap";
    ReadWritePaths = [ "/var/lib/stacks/lldap" ];
  };

  systemd.services.lldap-groups = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "lldap.service"
      "sops-install-secrets.service"
    ];
    wants = [
      "lldap.service"
      "sops-install-secrets.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.curl
      pkgs.jq
    ];
    script = ''
      set -eu
      api=http://127.0.0.1:5090
      token=$(curl -sf -X POST "$api/auth/simple/login" -H 'Content-Type: application/json' \
        -d "$(jq -cn --arg u admin --arg p "$(cat ${config.sops.secrets."lldap/admin_password".path})" '{username: $u, password: $p}')" |
        jq -r .token)
      have=$(curl -sf -X POST "$api/api/graphql" -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
        -d '{"query":"{ groups { displayName } }"}' | jq -r '.data.groups[].displayName')
      for g in ${lib.concatStringsSep " " serviceGroups}; do
        if ! printf '%s\n' "$have" | grep -qx "$g"; then
          curl -sf -X POST "$api/api/graphql" -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
            -d "$(jq -cn --arg q "mutation { createGroup(name: \"$g\") { id } }" '{query: $q}')" > /dev/null
          echo "created $g"
        fi
      done
    '';
  };

  services.caddy.virtualHosts."admin.karthihegde.dev".extraConfig = ''
    import auth
    reverse_proxy 127.0.0.1:5090
  '';
}
