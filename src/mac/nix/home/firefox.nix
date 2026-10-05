{ pkgs, lib, ... }:

let
  # about:config settings, written to the profile's user.js
  prefs = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "sidebar.revamp" = true;
    "sidebar.verticalTabs" = true;
    "sidebar.visibility" = "expand-on-hover";
    "sidebar.animation.expand-on-hover.delay-duration-ms" = 0;
    "browser.toolbars.bookmarks.visibility" = "never";
    "browser.newtabpage.enabled" = false;
    "sidebar.main.tools" = "history,bookmarks";
    "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
    "browser.startup.page" = 3;
  };
  userJs = pkgs.writeText "user.js" (
    lib.concatStrings (
      lib.mapAttrsToList (k: v: "user_pref(${builtins.toJSON k}, ${builtins.toJSON v});\n") prefs
    )
  );

  # Lets Firefox run userChrome .uc.js scripts (like newtab-popup.uc.js):
  # autoconfig points Firefox at config.js, which loads them. Both live inside
  # the app, so a Firefox update wipes them; every switch puts them back.
  autoconfigJs = pkgs.writeText "autoconfig.js" ''
    pref("general.config.filename", "config.js");
    pref("general.config.obscure_value", 0);
    pref("general.config.sandbox_enabled", false);
  '';
  configJs = pkgs.writeText "config.js" ''
    //
    const manifest = Services.dirsvc.get("UChrm", Ci.nsIFile);
    manifest.append("chrome.manifest");
    Components.manager.QueryInterface(Ci.nsIComponentRegistrar).autoRegister(manifest);

    Services.obs.addObserver((window) => {
      const entries = Services.dirsvc.get("UChrm", Ci.nsIFile).directoryEntries;
      while (entries.hasMoreElements()) {
        const name = entries.nextFile.leafName;
        if (name.endsWith(".uc.js")) {
          Services.scriptloader.loadSubScript(`chrome://userchromejs/content/''${name}`, window);
        }
      }
    }, "browser-delayed-startup-finished");
  '';
in
{
  # Firefox's profile folder has a random name, so it can't be a home.file
  # target. Link chrome/ and user.js into the default-release profile once
  # it exists, and install the autoconfig loader into the app.
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
      linkFirefox ${../../../../config/firefox/chrome} "$firefoxDir/$profile/chrome"
      linkFirefox ${userJs} "$firefoxDir/$profile/user.js"
    fi

    app=/Applications/Firefox.app/Contents/Resources
    if [ -d "$app" ]; then
      cmp -s ${autoconfigJs} "$app/defaults/pref/autoconfig.js" || run install -m 644 ${autoconfigJs} "$app/defaults/pref/autoconfig.js"
      cmp -s ${configJs} "$app/config.js" || run install -m 644 ${configJs} "$app/config.js"
    fi
  '';
}
