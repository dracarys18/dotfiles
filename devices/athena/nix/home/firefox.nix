{
  config,
  pkgs,
  lib,
  writable,
  ...
}:

let
  # The profile in profiles.ini below; an existing Mac already has it
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

    # Firefox 158 opens a "get started" profile picker when its Profile Groups
    # database has no entry; it ignored profiles.ini and looked like a fresh
    # install. Turning the feature off restores classic profiles.ini selection.
    "browser.profiles.enabled" = false;
    "browser.profiles.createdbrowser" = true;

    # Memory: with defaults this session had 26 processes and 6.4 GB resident.
    # Fewer content processes (8 -> 4), fewer back/forward pages kept alive,
    # and smaller disk/media caches. Needs a Firefox restart to take effect.
    "dom.ipc.processCount" = 4;
    "browser.sessionhistory.max_total_viewers" = 2;
    "browser.cache.memory.capacity" = 65536; # KB, 64 MB
    "media.cache_size" = 131072; # KB, 128 MB (default 512 MB)
    # macOS memory pressure still unloads tabs, but sooner than 10 minutes
    "browser.tabs.unloadOnLowMemory" = true;
    "browser.tabs.min_inactive_duration_before_unload" = 300000;
  };

  # Firefox with the autoconfig baked in: it loads the profile's .uc.js scripts
  # (newtab-popup.uc.js binds cmd+; to "open the URL bar in a new tab") at
  # startup. nixpkgs' wrapper writes these into the app in the store, so the
  # loader survives Firefox updates. A cask cannot do this: injecting files into
  # a signed bundle breaks its seal and Gatekeeper calls the app "damaged".
  # Cost of staying on Nix: after a Firefox update, macOS asks again for
  # microphone / camera / screen-recording.
  firefox = pkgs.firefox.override {
    # plain string concatenation: the wrapper writes mozilla.cfg through an
    # unquoted shell heredoc, which eats backticks and $ in template literals
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
    # autoconfig, not user.js: Firefox 158 picks its profile before any profile
    # prefs are read, and its Profile Groups database has no entry, so it opens
    # a "get started" picker and ignores profiles.ini. This has to be an
    # app-level default to be seen in time.
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
    # policies land in Firefox's macOS defaults too (home-manager's own
    # default domain name has a stray ".plist"), so `about:policies` shows them
    darwinDefaultsId = "org.mozilla.firefox";
    # email links go to Gmail; only mailto changes, every other handler stays
    # as set in Firefox
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

  # `force` replaces what's there without a backup: Firefox rewrites
  # profiles.ini when its install records change, so home-manager's goes back
  # on every switch; chrome and user.js were links into the Nix store
  home.file = {
    # userChrome.css and the .uc.js scripts the autoconfig above loads
    "${profilesPath}/${profilePath}/chrome" = {
      source = ../../../../config/firefox/chrome;
      force = true;
    };
    "${profilesPath}/${profilePath}/user.js".force = true;
    # writable, not a store symlink: Firefox 158 records profile groups in
    # Profile Groups/*.sqlite and needs to write here too, otherwise it ignores
    # this file and starts the "get started" flow with an empty profile
    "${configPath}/profiles.ini" = {
      source = writable "config/firefox/profiles.ini";
      force = true;
    };
  };

  # Email links open Firefox (which sends them to Gmail) instead of Apple Mail
  home.activation.firefoxMailto = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pkgs.duti} -s org.mozilla.firefox mailto
  '';
}
