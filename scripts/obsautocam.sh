#!/usr/bin/env bash
# obsautocam.sh — run OBS and its virtual camera only while an app is using it.
# Idempotent: rebuilds the watcher, turns on obs-websocket and reloads the launch agent.
# Pass --uninstall to remove the watcher and its launch agent.
#
# The watcher source lives in <dotfiles>/obs/autocam.swift. yabai places the OBS
# window on the labelled "obs" desktop (see yabai/yabairc).

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.$(id -un).obs-autocam"
DOMAIN="gui/$(id -u)"
BIN="$HOME/.local/bin/obs-autocam"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/obs-autocam.log"
WEBSOCKET_CONFIG="$HOME/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "  skip   obs-autocam (macOS only)"
    exit 0
fi

unload() {
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
    for _ in $(seq 1 25); do
        launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 || return 0
        sleep 0.2
    done
}

if [ "${1:-}" = "--uninstall" ]; then
    unload
    rm -f "$PLIST" "$BIN"
    echo "  removed obs-autocam (obs-websocket settings left as they are)"
    exit 0
fi

echo "Checking what obs-autocam needs"
if ! command -v swiftc >/dev/null 2>&1; then
    echo "  missing swiftc — run: xcode-select --install"
    exit 1
fi
if ! open -Ra OBS 2>/dev/null; then
    echo "  missing OBS — run: brew install --cask obs"
    exit 1
fi
echo "  found  swiftc, OBS"

echo "Building the watcher"
mkdir -p "$(dirname "$BIN")"
swiftc -O -swift-version 6 "$DOTFILES/obs/autocam.swift" -o "$BIN"
echo "  built  $BIN"

echo "Turning on obs-websocket"
if pgrep -xq OBS; then
    echo "  skip   OBS is running — quit it and rerun so OBS doesn't overwrite the settings"
else
    mkdir -p "$(dirname "$WEBSOCKET_CONFIG")"
    /usr/bin/python3 - "$WEBSOCKET_CONFIG" <<'PY'
import json
import os
import secrets
import sys

path = sys.argv[1]
config = json.load(open(path)) if os.path.exists(path) else {}
config["server_enabled"] = True
config["first_load"] = False
config.setdefault("server_port", 4455)
if not config.get("auth_required") or not config.get("server_password"):
    config["auth_required"] = True
    config["server_password"] = secrets.token_urlsafe(24)
with open(path, "w") as f:
    json.dump(config, f, indent=4)
PY
    echo "  enabled obs-websocket (password auth)"
fi

echo "Loading the launch agent"
mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
</dict>
</plist>
PLIST
unload
launchctl bootstrap "$DOMAIN" "$PLIST"
echo "  loaded $LABEL"

echo
echo "Done. OBS now starts when an app opens \"OBS Virtual Camera\" and quits when it lets go."
echo "  log: $LOG"
