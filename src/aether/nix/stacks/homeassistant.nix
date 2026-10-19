# ~/Projects/homeassistant — both services need the host network
{ ... }:

let
  d = "/var/lib/stacks/homeassistant";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config ${d}/matter-data 0755 root root -"
  ];

  virtualisation.oci-containers.containers = {
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      environment.TZ = "Asia/Kolkata";
      volumes = [
        "${d}/config:/config"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };

    matter-server = {
      image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
      volumes = [
        "${d}/matter-data:/data"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--network=host"
        "--security-opt=apparmor=unconfined"
      ];
    };
  };
}
