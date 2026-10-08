# OBS: settings snapshot, `obs-save`, and the camera watcher that runs OBS
# only while an app uses its virtual camera.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Needs Swift 6 (nixpkgs has 5.10), so it's built with Apple's swiftc;
  # Nix's build sandbox is off on macOS, so the Xcode toolchain is reachable.
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

  # obs-save: copy OBS settings into the repo with stream keys and logins
  # blanked. OBS replaces its files on every save, so they can't be links.
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
      DST="$HOME/dotfiles/src/mac/config/obs"

      rm -rf "$DST"
      mkdir -p "$DST"
      cp "$SRC/global.ini" "$SRC/user.ini" "$DST/"
      # profiles and scene collections, without OBS's own .bak copies
      (cd "$SRC" && find basic -type f \( -name '*.ini' -o -name '*.json' \) -print0) |
          while IFS= read -r -d ''' f; do
              mkdir -p "$DST/$(dirname "$f")"
              cp "$SRC/$f" "$DST/$f"
          done

      # Blank the secrets: stream keys and tokens in JSON, and the Token=,
      # RefreshToken= and *Password= lines (account logins) in INI files.
      # OBS may start a file with a byte order mark; drop it.
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

  # the watcher talks to OBS over obs-websocket, so make sure it's on, with a
  # password (24 random bytes, URL-safe base64)
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

  # Copy the repo snapshot in for files OBS doesn't have yet (a fresh Mac);
  # files OBS already has are never touched. Then turn obs-websocket on,
  # unless OBS is running (it would overwrite the file when it quits).
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
