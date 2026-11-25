let
  user = "karthihegde";
in
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleIconAppearanceTheme = "ClearDark";
      _HIHideMenuBar = true;
      AppleSpacesSwitchOnActivate = false;
      NSTableViewDefaultSizeMode = 3; # large sidebar icons
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      ApplePressAndHoldEnabled = false; # held keys repeat, no accent menu
      NSDocumentSaveNewDocumentsToCloud = false; # save to this Mac, not iCloud
      "com.apple.sound.beep.volume" = 0.4345982;
    };
    dock = {
      autohide = true;
      autohide-delay = 0.0;
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
        "/Applications/Vesktop.app"
        "/Applications/Signal.app"
        "/Users/${user}/Applications/Home Manager Apps/LibreWolf.app"
        "/Applications/Telegram.app"
      ];
    };
    finder = {
      FXPreferredViewStyle = "Nlsv"; # list view
      FXRemoveOldTrashItems = true; # empty Trash after 30 days
      ShowPathbar = true;
      _FXSortFoldersFirst = true;
    };
    WindowManager = {
      GloballyEnabled = false; # Stage Manager off
      EnableTiledWindowMargins = false;
      EnableStandardClickToShowDesktop = false; # clicking the wallpaper hides nothing
      HideDesktop = true;
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
    };
    screencapture.disable-shadow = true;
    hitoolbox.AppleFnUsageType = "Do Nothing";
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
        SiriPrefStashedStatusMenuVisible = false;
      };
      "com.apple.desktopservices".DSDontWriteNetworkStores = true;
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      "com.apple.assistant.support" = {
        "Siri Data Sharing Opt-In Status" = 2;
        "Search Queries Data Sharing Status" = 2;
        "Assistant Enabled" = false;
      };
      "com.apple.lookup.shared".LookupSuggestionsDisabled = true;
    };
  };

  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

    uid="$(id -u -- ${user})"
    launchctl asuser "$uid" launchctl kickstart -k "gui/$uid/org.nixos.skhd" || true
    launchctl asuser "$uid" launchctl kickstart -k "gui/$uid/org.nixos.yabai" || true
  '';

  home-manager.users.${user}.targets.darwin.currentHostDefaults."com.apple.screensaver".idleTime = 0;
}
