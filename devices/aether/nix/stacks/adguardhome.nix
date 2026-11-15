# ~/Projects/adguardhome — this box is the tailnet's resolver, so it is the
# last stack to switch over. AdGuard Home does the filtering per client and
# resolves upstream through dnscrypt-proxy (see configuration.nix).
#
# It runs with host networking, unlike every other stack: :53 has to be
# reachable from the LAN and the tailnet, and a published port is DNAT'd
# straight past NixOS's firewall (which only builds an INPUT chain). On the
# host network the queries land on INPUT, where firewall.nix decides that the
# LAN and the tailnet may resolve and the internet may not. Nothing else needs
# the fixed 10.99.0.2 address it used to have.
#
# The config is AdGuardHome.yaml beside this file, not the app's own state. AGH
# rewrites its config on every settings change, so a runtime file drifts and
# the drift is invisible in the repo; adguardhome-config overwrites the file
# from the store before every start instead, which makes this one the source of
# truth and throws away whatever the UI left behind. The admin password is a
# bcrypt hash in sops; upstreams, blocklists and per-client rules are plain
# config.
#
# It cannot bind 0.0.0.0:53: podman's DNS (aardvark-dns) holds 10.88.0.1:53 on
# the host stack, and a wildcard bind fails while a specific address on the
# same port is taken. The config therefore lists the addresses it serves,
# which means the tailnet address has to exist before it starts — that is why
# one of the bind_hosts is a literal tailnet IP.
#
# DoT is served with a certificate from a CA of our own (dot-ca.pem beside this
# file), not with the one caddy holds for dns.karthihegde.dev: that one lives
# under /var/lib/caddy and is renewed on a schedule, so it would have to be
# copied out and kept in step forever, and a stale copy is a resolver that stops
# verifying. The CA key was deleted after signing, which leaves nothing on this
# box able to mint a second certificate for adguard.aether.internal, and the
# leaf and its key are in sops. AdGuard's HTTPS and DoQ listeners are on port 0
# in AdGuardHome.yaml because 443 belongs to caddy and TLS here is for the DNS
# hop only.
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

  # yaml, not dotenv: sops-install-secrets ignores `key` for dotenv files and
  # hands the template the whole decrypted file, which would have put every
  # line of it into the password field
  sops.secrets."adguardhome/password_hash" = {
    sopsFile = ../secrets/adguardhome.yaml;
    key = "password_hash";
    mode = "0400";
    restartUnits = [
      "adguardhome-config.service"
      "podman-adguardhome.service"
    ];
  };


  # resolved verifies the DoT hop to AdGuard against this and nothing else, so
  # the leaf never has to be publicly trusted
  security.pki.certificateFiles = [ ./adguardhome/dot-ca.pem ];

  # the leaf and its key, installed into the conf dir below rather than mounted
  # from /run/secrets: the config unit already runs before the container and can
  # make the directory in one step, and a mount whose source is missing is a
  # directory podman creates on the host instead
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

  # the container keeps the conf dir writable, because AGH saves the config
  # whenever a setting changes and errors on every write otherwise. What it
  # saves is discarded at the next start, so the repo wins without the app
  # having to cope with a read-only file.
  #
  # sops.templates would be the obvious way to build this file, and it is how
  # cartero does it, but its output under /run/secrets/rendered cannot be
  # ordered against a unit start here: a deploy was seen to start the container
  # against the *previous* render, and AGH then died parsing it. Reading the
  # store copy and the secret directly cannot go stale — the config is whatever
  # generation is being activated, and the only stale thing possible is an
  # older bcrypt hash, which still parses.
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

  # Editing AdGuardHome.yaml leaves this unit's own definition identical, and
  # switch-to-configuration does not restart a unit for that alone — the deploy
  # would install the new file and leave the old config running in memory.
  # Trigger a restart on the store copy of the file, whose path changes
  # whenever its contents do, so a config edit always lands.
  systemd.services.podman-adguardhome = {
    restartTriggers = [ ./adguardhome/AdGuardHome.yaml ];
    after = [ "tailscaled.service" ];
  };

  # resolved has no way back to the first server on its own. When adguard is
  # restarted, a query that lands in the gap marks it failed and every later
  # query follows cloudflare — the box stays unfiltered after adguard is up
  # again, and resetting the learnt feature levels does not move it back. So the
  # restart carries a restart of resolved, gated on adguard actually answering
  # DoT with the certificate resolved is about to check.
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
