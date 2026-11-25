{ config, ... }:

let
  d = "/var/lib/stacks/obsidian";
in
{
  services.caddy.virtualHosts."note.${config.homelab.domain}".extraConfig = "import proxy 5984";

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/couchdb-data 0755 5984 5984 -"
    "d ${d}/couchdb-etc 0755 5984 5984 -"
  ];

  virtualisation.oci-containers.containers.couchdb-for-ols = {
    image = "couchdb@sha256:0ba6b4b8dd823232185fa2c7de04634b925be62f97c9b7cbece7dd9119470e17";
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
