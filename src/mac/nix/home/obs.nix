{ config, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  # OBS replaces its settings files on every save, so they can't be links.
  # Copy the repo snapshot in for files OBS doesn't have yet (a fresh Mac);
  # files OBS already has are never touched. src/mac/scripts/obs-save.sh
  # refreshes the snapshot. Stream keys and logins aren't in it.
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
  '';

  # Rebuild and reload the OBS camera watcher when its code changes. It needs
  # Swift 6 (nixpkgs has 5.10), so it builds with Apple's swiftc.
  home.activation.obsAutocam = lib.hm.dag.entryAfter [ "obsSettings" ] ''
    stamp="$HOME/.local/state/obs-autocam.hash"
    hash=${
      builtins.hashString "sha256" (
        builtins.readFile ../../obs/autocam.swift + builtins.readFile ../../scripts/obsautocam.sh
      )
    }
    if [ "$(cat "$stamp" 2>/dev/null)" != "$hash" ]; then
      if run env PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash ${dotfiles}/src/mac/scripts/obsautocam.sh; then
        run mkdir -p "$(dirname "$stamp")"
        run sh -c 'echo "$1" > "$2"' _ "$hash" "$stamp"
      else
        echo "obs-autocam setup failed; it will be retried on the next switch"
      fi
    fi
  '';
}
