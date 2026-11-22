{
  config,
  lib,
  pkgs,
  ...
}:

let
  autocam = pkgs.stdenvNoCC.mkDerivation {
    name = "obs-autocam";
    src = ../../obs/autocam.swift;
    dontUnpack = true;
    buildPhase = ''
      unset SDKROOT DEVELOPER_DIR MACOSX_DEPLOYMENT_TARGET
      HOME=$TMPDIR /usr/bin/swiftc -O -swift-version 6 $src -o obs-autocam
    '';
    installPhase = "mkdir -p $out/bin && cp obs-autocam $out/bin/";
  };

  obsSave = pkgs.writeShellApplication {
    name = "obs-save";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnused
      jq
    ];
    text = ''
      SRC="$HOME/Library/Application Support/obs-studio"
      DST="$HOME/dotfiles/devices/athena/config/obs"

      rm -rf "$DST"
      mkdir -p "$DST"
      cp "$SRC/global.ini" "$SRC/user.ini" "$DST/"
      (cd "$SRC" && find basic -type f \( -name '*.ini' -o -name '*.json' \) -print0) |
          while IFS= read -r -d ''' f; do
              mkdir -p "$DST/$(dirname "$f")"
              cp "$SRC/$f" "$DST/$f"
          done

      find "$DST" -type f -name '*.json' -print0 | while IFS= read -r -d ''' f; do
          sed '1s/^\xEF\xBB\xBF//' "$f" | jq --indent 4 --ascii-output '
              walk(if type == "object" then with_entries(
                  if (.value | type) == "string"
                      and (.key | ascii_downcase | IN("key", "password", "token", "bearer_token", "refresh_token", "stream_key"))
                  then .value = "" else . end
              ) else . end)' > "$f.tmp"
          mv "$f.tmp" "$f"
      done
      find "$DST" -type f -name '*.ini' -exec \
          sed -i -E '1s/^\xEF\xBB\xBF//; s/^((Refresh)?Token|[[:alnum:]_]*Password)=.*$/\1=/' {} +

      echo "  saved OBS settings to $DST (secrets blanked)"
    '';
  };

  enableWebsocket = pkgs.writeShellApplication {
    name = "obs-websocket-enable";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      config="$1"
      current=$(cat "$config" 2>/dev/null || echo '{}')
      password=$(head -c 24 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=')
      new=$(jq --indent 4 --arg password "$password" '
          .server_enabled = true
          | .first_load = false
          | if has("server_port") then . else .server_port = 4455 end
          | if (.auth_required | not) or ((.server_password // "") == "")
            then .auth_required = true | .server_password = $password
            else . end' <<<"$current")
      if [ "$new" != "$(jq --indent 4 . <<<"$current")" ]; then
          mkdir -p "$(dirname "$config")"
          printf '%s\n' "$new" > "$config"
      fi
    '';
  };
in
{
  home.packages = [ obsSave ];

  launchd.agents.obs-autocam = {
    enable = true;
    config = {
      ProgramArguments = [ "${autocam}/bin/obs-autocam" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/obs-autocam.log";
    };
  };

  home.activation.obsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    obsDir="$HOME/Library/Application Support/obs-studio"
    (
      cd ${../../config/obs}
      find . -type f | while read -r f; do
        if [ ! -e "$obsDir/$f" ]; then
          run mkdir -p "$(dirname "$obsDir/$f")"
          run install -m 644 "$f" "$obsDir/$f"
        fi
      done
    )
    if ! /usr/bin/pgrep -xq OBS; then
      run ${lib.getExe enableWebsocket} "$obsDir/plugin_config/obs-websocket/config.json"
    fi
  '';
}
