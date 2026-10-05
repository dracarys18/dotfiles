# stylix's colours as a Vencord theme in Vesktop. Only the theme is managed:
# Vencord's own settings (plugins etc.) stay yours to change in the app, so
# they aren't taken over by Nix as read-only files.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dir = "${config.home.homeDirectory}/Library/Application Support/vesktop";
in
{
  home.file."Library/Application Support/vesktop/themes/stylix.css".text =
    config.stylix.targets.vesktop.themeBody;

  # switch the theme on once; restart Vesktop if it was running
  home.activation.vesktopTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${dir}/settings/settings.json"
    if [ -f "$settings" ] && ! ${pkgs.jq}/bin/jq -e '(.enabledThemes // []) | index("stylix.css")' "$settings" >/dev/null; then
      run ${pkgs.bash}/bin/bash -c '${pkgs.jq}/bin/jq ".enabledThemes = ((.enabledThemes // []) + [\"stylix.css\"])" "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ "$settings"
    fi
  '';
}
