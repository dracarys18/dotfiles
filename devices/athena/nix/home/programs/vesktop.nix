# catppuccin's Discord theme in Vesktop. catppuccin/nix declares it for
# programs.vesktop, which would also turn Vencord's own settings (plugins etc.)
# into read-only Nix files; take only the theme from it, so the settings stay
# yours to change in the app.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dir = "${config.home.homeDirectory}/Library/Application Support/vesktop";
  jq = "${pkgs.jq}/bin/jq";
  inherit (config.programs.vesktop.vencord) themes;
  enabled = config.programs.vesktop.vencord.settings.enabledThemes;
in
{
  home.file = lib.mapAttrs' (
    name: theme:
    lib.nameValuePair "Library/Application Support/vesktop/themes/${name}.css" (
      if builtins.isPath theme || lib.isStorePath theme then { source = theme; } else { text = theme; }
    )
  ) themes;

  # switch the theme on, and off any theme whose file is gone (like one Nix
  # used to install); restart Vesktop if it was running
  home.activation.vesktopTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings="${dir}/settings/settings.json"
    if [ -f "$settings" ]; then
      present=$(ls "${dir}/themes" 2>/dev/null | ${jq} -R . | ${jq} -s .)
      new=$(${jq} --argjson want '${builtins.toJSON enabled}' --argjson present "$present" \
        '.enabledThemes = ([(.enabledThemes // [])[] | select(IN($present[]))] - $want) + $want' "$settings")
      if [ "$new" != "$(${jq} . "$settings")" ]; then
        run ${pkgs.bash}/bin/bash -c 'printf "%s\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"' _ "$settings" "$new"
      fi
    fi
  '';
}
