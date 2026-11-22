{
  config,
  pkgs,
  lib,
  writable,
  ...
}:

let
  profilePath = "714unkms.default-release-1790774533806";

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
    "browser.download.alwaysOpenPanel" = false;
    "browser.startup.page" = 3;

    "browser.profiles.enabled" = false;
    "browser.profiles.createdbrowser" = true;

    "dom.ipc.processCount" = 4;
    "browser.sessionhistory.max_total_viewers" = 2;
    "browser.cache.memory.capacity" = 65536; # KB, 64 MB
    "media.cache_size" = 131072; # KB, 128 MB (default 512 MB)
    "browser.tabs.unloadOnLowMemory" = true;
    "browser.tabs.min_inactive_duration_before_unload" = 300000;
  };

  firefox = pkgs.firefox.override {
    extraPrefs = ''
      const manifest = Services.dirsvc.get("UChrm", Ci.nsIFile);
      manifest.append("chrome.manifest");
      Components.manager.QueryInterface(Ci.nsIComponentRegistrar).autoRegister(manifest);

      Services.obs.addObserver((window) => {
        const entries = Services.dirsvc.get("UChrm", Ci.nsIFile).directoryEntries;
        while (entries.hasMoreElements()) {
          const name = entries.nextFile.leafName;
          if (name.endsWith(".uc.js")) {
            Services.scriptloader.loadSubScript("chrome://userchromejs/content/" + name, window);
          }
        }
      }, "browser-delayed-startup-finished");
    '';
    extraAutoConfig = ''
      pref("general.config.sandbox_enabled", false);
      pref("browser.profiles.enabled", false);
    '';
  };

  inherit (config.programs.firefox) configPath profilesPath;
in
{
  programs.firefox = {
    enable = true;
    package = firefox;
    darwinDefaultsId = "org.mozilla.firefox";
    policies.Handlers.schemes.mailto = {
      action = "useHelperApp";
      ask = false;
      handlers = [
        {
          name = "Gmail";
          uriTemplate = "https://mail.google.com/mail/?extsrc=mailto&url=%s";
        }
      ];
    };
    profiles.default-release = {
      id = 0;
      isDefault = true;
      path = profilePath;
      settings = prefs;
    };
  };

  home.file = {
    "${profilesPath}/${profilePath}/chrome" = {
      source = ../../../../config/firefox/chrome;
      force = true;
    };
    "${profilesPath}/${profilePath}/user.js".force = true;
    "${configPath}/profiles.ini" = {
      source = writable "config/firefox/profiles.ini";
      force = true;
    };
  };

  home.activation.firefoxMailto = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pkgs.duti} -s org.mozilla.firefox mailto
  '';
}
