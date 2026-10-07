# Apple Intelligence off, its models deleted and blocked from downloading
# again, with pared (github.com/4evy/pared). debloat.nix stops its services.
{ pkgs, inputs, ... }:

let
  user = "karthihegde";
  profile = "/etc/pared/disable-apple-intelligence.mobileconfig";
in
{
  imports = [ inputs.pared.darwinModules.default ];

  # Every feature off; `features.<name> = true` keeps one (`pared features`
  # lists them). Activation deletes the models of every feature that's off.
  programs.pared = {
    enable = true;
    package = inputs.pared.packages.${pkgs.stdenv.hostPlatform.system}.pared;
  };

  # The profile locks the features off and blocks the downloads, but macOS
  # only installs a profile after a click in System Settings. Open it while
  # it isn't installed, and once more each time it changes.
  system.activationScripts.postActivation.text = ''
    opened=/var/db/pared/opened-profile.sha256
    sum=$(/usr/bin/shasum -a 256 ${profile} | /usr/bin/cut -d' ' -f1)
    if ! /usr/bin/profiles list | /usr/bin/grep -q org.pared.disable-apple-intelligence \
      || [ "$(cat "$opened" 2>/dev/null)" != "$sum" ]; then
      echo "approve the pared profile in System Settings > General > Device Management"
      launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- /usr/bin/open ${profile}
      mkdir -p /var/db/pared
      echo "$sum" > "$opened"
    fi
  '';
}
