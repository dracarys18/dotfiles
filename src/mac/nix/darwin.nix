# System level: Nix itself, the login shell, fonts, Homebrew apps, macOS settings.
{ pkgs, ... }:

let
  user = "karthihegde";
  uid = "501"; # `id -u`
in
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = user;

  users.users.${user}.home = "/Users/${user}";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  # fish from nixpkgs, registered in /etc/shells; the login shell is set below
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  fonts.packages = [ pkgs.nerd-fonts.hasklug ];

  # GUI apps and the few tools nixpkgs doesn't have for macOS. Anything not
  # listed here is uninstalled on every switch ("zap" also removes its app data).
  #
  # Keep cargo out of Homebrew and environment.systemPackages: if `brew bundle`
  # can see cargo during activation, its cleanup also runs `cargo uninstall` on
  # every crate not listed here, including local builds like uji.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
    taps = [
      {
        name = "asmvik/formulae";
        trusted = true;
      }
      {
        name = "tsirysndr/tap";
        trusted = true;
      }
    ];
    brews = [
      {
        name = "asmvik/formulae/skhd";
        trusted = true;
      }
      {
        name = "asmvik/formulae/yabai";
        link = false;
        trusted = true;
      }
      {
        name = "tsirysndr/tap/fin";
        trusted = true;
      }
      "firefoxpwa"
    ];
    casks = [
      "1password"
      "1password-cli"
      "adobe-acrobat-reader"
      "android-platform-tools"
      "claude-code@latest"
      "firefox"
      "ghostty"
      "kde-connect"
      "maccy"
      "obs"
      "signal"
      "spotify"
      "tailscale-app"
      "telegram"
      "vesktop"
      "vicinae"
    ];
    # Mac App Store apps (needs you signed in to the App Store)
    masApps = {
      Developer = 640199958;
      TestFlight = 899247664;
    };
  };

  # Settings changed from the macOS defaults, read off this Mac on 2026-10-05
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleIconAppearanceTheme = "ClearDark";
      _HIHideMenuBar = true;
      # don't jump to another Space when switching apps (yabai handles Spaces)
      AppleSpacesSwitchOnActivate = false;
      NSTableViewDefaultSizeMode = 3; # large sidebar icons
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.sound.beep.volume" = 0.4345982;
    };
    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 16;
      largesize = 16;
      magnification = false;
      launchanim = false;
      mineffect = "scale";
      mru-spaces = false;
      show-recents = false;
      expose-animation-duration = 0.1;
      persistent-apps = [
        "/Applications/Ghostty.app"
        "/Applications/Firefox.app"
      ];
    };
    finder = {
      FXPreferredViewStyle = "Nlsv"; # list view
      FXRemoveOldTrashItems = true; # empty Trash after 30 days
    };
    WindowManager = {
      GloballyEnabled = false; # Stage Manager off
      EnableTiledWindowMargins = false;
      HideDesktop = true;
      StageManagerHideWidgets = true;
    };
    hitoolbox.AppleFnUsageType = "Do Nothing";
    # settings nix-darwin has no option for
    CustomUserPreferences = {
      NSGlobalDomain = {
        WebAutomaticSpellingCorrectionEnabled = false;
        UIPreferredContentSizeCategoryName = "UICTContentSizeCategoryXXXL";
        "com.apple.sound.beep.sound" = "/System/Library/Sounds/Blow.aiff";
      };
      "com.apple.loginwindow" = {
        TALLogoutSavesState = false; # don't reopen windows after login
        ClockFontIdentifier = "slab";
      };
      "com.apple.Siri" = {
        StatusMenuVisible = false;
        VoiceTriggerUserEnabled = false;
      };
    };
  };

  # Siri, Apple Intelligence, analytics and telemetry stay off. Applied on every
  # switch (below) and again at boot and login, since launchd re-enables some.
  launchd.daemons.debloat.serviceConfig = {
    ProgramArguments = [
      "/bin/bash"
      "${../scripts/debloat.sh}"
      "--boot"
      uid
    ];
    RunAtLoad = true;
  };

  # Activation runs as root, so these use dscl (no password, unlike chsh) and
  # run user settings as the user.
  system.activationScripts.postActivation.text = ''
    echo "setting login shell to nix fish..."
    dscl . -create /Users/${user} UserShell /run/current-system/sw/bin/fish

    # Free cmd+space for vicinae: turn off the Spotlight shortcut (symbolic
    # hotkey 64). -dict-add keeps every other hotkey as it is.
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

    # Never start the screen saver (a per-host setting, which nix-darwin can't set)
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      defaults -currentHost write com.apple.screensaver idleTime -int 0

    # The debloat boot service used to install itself; launchd.daemons.debloat
    # replaces it, so remove the old copy if it's still around
    if [ -e /Library/LaunchDaemons/com.${user}.debloat.plist ]; then
      launchctl bootout system/com.${user}.debloat 2>/dev/null || true
      rm -f /Library/LaunchDaemons/com.${user}.debloat.plist /usr/local/libexec/debloat.sh
    fi

    echo "debloating..."
    PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash ${../scripts/debloat.sh} ${uid}
  '';
}
