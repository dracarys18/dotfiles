{ config, ... }:

let
  d = "/var/lib/stacks/obsidian";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/couchdb-data 0755 5984 5984 -"
    "d ${d}/couchdb-etc 0755 5984 5984 -"
  ];

  virtualisation.oci-containers.containers.couchdb-for-ols = {
    image = "couchdb:3.5";
    extraOptions = [ "--pull=newer" ];
    user = "5984:5984";
    environment.COUCHDB_USER = "obsidian_admin";
    environmentFiles = [ config.sops.secrets."obsidian".path ];
    volumes = [
      "${d}/couchdb-data:/opt/couchdb/data"
      "${d}/couchdb-etc:/opt/couchdb/etc/local.d"
      "${./obsidian-couchdb.ini}:/opt/couchdb/etc/local.d/10-obsidian.ini:ro"
    ];
    ports = [ "127.0.0.1:5984:5984" ];
  };
}
