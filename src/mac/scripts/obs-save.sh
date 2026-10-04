#!/usr/bin/env bash
# obs-save.sh — copy OBS settings into the repo, with stream keys and login
# tokens blanked so they never reach git.
#
# OBS replaces its settings files every time it saves, so they can't be linked
# like other configs. home.nix copies this snapshot into OBS on a fresh Mac
# (only files OBS doesn't have yet); run this after changing settings you want
# to keep, then commit.

set -euo pipefail

SRC="$HOME/Library/Application Support/obs-studio"
DST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/obs"

rm -rf "$DST"
mkdir -p "$DST"
cp "$SRC/global.ini" "$SRC/user.ini" "$DST/"
# profiles and scene collections, without OBS's own .bak copies
(cd "$SRC" && find basic -type f \( -name '*.ini' -o -name '*.json' \) -print0) |
    while IFS= read -r -d '' f; do
        mkdir -p "$DST/$(dirname "$f")"
        cp "$SRC/$f" "$DST/$f"
    done

/usr/bin/python3 - "$DST" <<'PY'
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
