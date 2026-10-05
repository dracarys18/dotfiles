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
  obsSave = pkgs.writeShellScriptBin "obs-save" ''
    set -euo pipefail

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

    ${pkgs.python3}/bin/python3 - "$DST" <<'PY'
    import configparser, json, pathlib, re, sys

    SECRET_JSON_KEYS = {"key", "password", "token", "bearer_token", "refresh_token", "stream_key"}

    def blank(o):
        if isinstance(o, dict):
            return {k: "" if k.lower() in SECRET_JSON_KEYS and isinstance(v, str) else blank(v) for k, v in o.items()}
        if isinstance(o, list):
            return [blank(v) for v in o]
        return o

    for p in pathlib.Path(sys.argv[1]).rglob("*"):
        if p.suffix == ".json":
            raw = p.read_text(encoding="utf-8-sig")
            p.write_text(json.dumps(blank(json.loads(raw)), indent=4) + "\n")
        elif p.suffix == ".ini":
            # Token=, RefreshToken= and *Password= lines carry account logins
            text = re.sub(r"(?m)^((?:Refresh)?Token|\w*Password)=.*$", r"\1=", p.read_text(encoding="utf-8-sig"))
            p.write_text(text)
    PY

    echo "  saved OBS settings to $DST (secrets blanked)"
  '';

  # the watcher talks to OBS over obs-websocket, so make sure it's on
  enableWebsocket = pkgs.writeText "obs-websocket.py" ''
    import json, os, secrets, sys

    path = sys.argv[1]
    config = json.load(open(path)) if os.path.exists(path) else {}
    before = dict(config)
    config["server_enabled"] = True
    config["first_load"] = False
    config.setdefault("server_port", 4455)
    if not config.get("auth_required") or not config.get("server_password"):
        config["auth_required"] = True
        config["server_password"] = secrets.token_urlsafe(24)
    if config != before:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump(config, f, indent=4)
  '';
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
      run ${pkgs.python3}/bin/python3 ${enableWebsocket} "$obsDir/plugin_config/obs-websocket/config.json"
    fi
  '';
}
