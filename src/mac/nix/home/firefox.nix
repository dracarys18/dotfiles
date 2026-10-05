{ pkgs, lib, ... }:

{
  # Firefox's profile folder has a random name, so it can't be a home.file
  # target. Link firefox/ into the default-release profile once it exists.
  home.activation.firefoxProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    firefoxDir="$HOME/Library/Application Support/Firefox"
    profile=$(${pkgs.gawk}/bin/awk -F= '
      /^\[/ { if (name == "default-release") print path; name = ""; path = "" }
      $1 == "Name" { name = $2 }
      $1 == "Path" { path = $2 }
      END { if (name == "default-release") print path }
    ' "$firefoxDir/profiles.ini" 2>/dev/null | head -1 || true)

    linkFirefox() {
      if [ -e "$2" ] && [ ! -L "$2" ]; then
        run mv "$2" "$2.before-nix"
      fi
      run ln -sfn "$1" "$2"
    }

    if [ -n "$profile" ]; then
      linkFirefox ${../../../../firefox/chrome} "$firefoxDir/$profile/chrome"
      linkFirefox ${../../../../firefox/user.js} "$firefoxDir/$profile/user.js"
    fi
  '';
}
