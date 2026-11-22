{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  user = "karthihegde";
  profile = "/etc/pared/disable-apple-intelligence.mobileconfig";
  pared = lib.getExe config.programs.pared.package;
in
{
  imports = [ inputs.pared.darwinModules.default ];

  programs.pared = {
    enable = true;
    package = inputs.pared.packages.${pkgs.stdenv.hostPlatform.system}.pared;
  };

  system.activationScripts.postActivation.text = ''
    opened=/var/db/pared/opened-profile.sha256
    sum=$(/usr/bin/shasum -a 256 ${profile} | /usr/bin/cut -d' ' -f1)
    if ! sudo --user=${user} -- ${pared} profile status >/dev/null 2>&1 \
      || [ "$(cat "$opened" 2>/dev/null)" != "$sum" ]; then
      echo "approve the pared profile in System Settings > General > Device Management"
      launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- /usr/bin/open ${profile}
      mkdir -p /var/db/pared
      echo "$sum" > "$opened"
    fi
  '';
}
