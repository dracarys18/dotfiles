{
  config,
  pkgs,
  lib,
  ...
}:

let
  # The profile Firefox.app (Homebrew) is locked to in installs.ini; a fresh
  # Mac gets it created at this path from the profiles.ini below.
  profilePath = "714unkms.default-release-1790774533806";

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
    # Auto-opening the downloads panel while the toolbar is hidden off-screen
    # (userChrome.css) leaves it stuck half-open, pinning the toolbar on top of
    # the page; the downloads button still shows progress
    "browser.download.alwaysOpenPanel" = false;
    "browser.startup.page" = 3;
  };

  # autoconfig points Firefox at config.js, which loads the profile's .uc.js
  # scripts (like newtab-popup.uc.js)
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
  inherit (config.programs.firefox) configPath profilesPath;
in
{
  # Firefox itself is the Homebrew cask; home-manager writes profiles.ini and
  # the profile's user.js. No enterprise policies, so it leaves Firefox's
  # macOS defaults alone.
  programs.firefox = {
    enable = true;
    package = null;
    darwinDefaultsId = null;
    profiles.default-release = {
      id = 0;
      isDefault = true;
      path = profilePath;
      settings = prefs;
    };
  };

  # `force` replaces what's there without a backup: Firefox rewrites
  # profiles.ini when its install records change, so home-manager's goes back
  # on every switch; chrome and user.js were links into the Nix store
  home.file = {
    # userChrome.css and the .uc.js scripts the autoconfig below loads
    "${profilesPath}/${profilePath}/chrome" = {
      source = ../../../../config/firefox/chrome;
      force = true;
    };
    "${profilesPath}/${profilePath}/user.js".force = true;
    "${configPath}/profiles.ini".force = true;
  };

  # Lets userChrome .uc.js scripts run. Autoconfig lives inside the app, so a
  # Firefox update wipes it; every switch puts it back.
  home.activation.firefoxAutoconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    app=/Applications/Firefox.app/Contents/Resources
    if [ -d "$app" ]; then
      cmp -s ${autoconfigJs} "$app/defaults/pref/autoconfig.js" || run install -m 644 ${autoconfigJs} "$app/defaults/pref/autoconfig.js"
      cmp -s ${configJs} "$app/config.js" || run install -m 644 ${configJs} "$app/config.js"
    fi
  '';
}
