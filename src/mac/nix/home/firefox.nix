{
  config,
  pkgs,
  lib,
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
  };

  # Firefox with the autoconfig baked in: it loads the profile's .uc.js scripts
  # (like newtab-popup.uc.js) at startup. nixpkgs' wrapper writes these into
  # the app in the store, so the loader survives Firefox updates, unlike the
  # copy the old /Applications install needed on every switch.
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
    # autoconfig runs in a sandbox by default; the script above uses Services
    extraAutoConfig = ''pref("general.config.sandbox_enabled", false);'';
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
    "${configPath}/profiles.ini".force = true;
  };

  # Email links open Firefox (which sends them to Gmail) instead of Apple Mail
  home.activation.firefoxMailto = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pkgs.duti} -s org.mozilla.firefox mailto
  '';
}
