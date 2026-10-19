# ~/Projects/kimai
{ config, ... }:

let
  d = "/var/lib/stacks/kimai";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/mysql ${d}/data ${d}/plugins 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 8001 ];

  virtualisation.oci-containers.containers = {
    sqldb = {
      image = "mysql:8.3";
      # MYSQL_PASSWORD and MYSQL_ROOT_PASSWORD live in the env file
      environment = {
        MYSQL_DATABASE = "kimai";
        MYSQL_USER = "kimaiuser";
      };
      environmentFiles = [ config.sops.secrets."kimai".path ];
      volumes = [ "${d}/mysql:/var/lib/mysql" ];
      cmd = [ "--default-storage-engine=innodb" ];
    };

    kimai = {
      image = "kimai/kimai2:stable";
      # APP_SECRET, ADMINPASS and DATABASE_URL (it carries the password) are
      # all in the env file
      environment = {
        TRUSTED_HOSTS = "lance.karthihegde.dev";
        ADMINMAIL = "karuhegde4343@gmail.com";
      };
      environmentFiles = [ config.sops.secrets."kimai".path ];
      volumes = [
        "${d}/data:/opt/kimai/var/data"
        "${d}/plugins:/opt/kimai/var/plugins"
      ];
      ports = [ "8001:8001" ];
      dependsOn = [ "sqldb" ];
    };
  };
}
