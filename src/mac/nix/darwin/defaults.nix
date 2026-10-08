let
  user = "karthihegde";
in
{
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
        "/Applications/Firefox.app"
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
      # no .DS_Store files on network drives
      "com.apple.desktopservices".DSDontWriteNetworkStores = true;
      # Privacy: no personalized ads, Improve Siri, Improve Search or Look Up
      # suggestions (2 = opted out)
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      "com.apple.assistant.support" = {
        "Siri Data Sharing Opt-In Status" = 2;
        "Search Queries Data Sharing Status" = 2;
      };
      "com.apple.lookup.shared".LookupSuggestionsDisabled = true;
    };
  };

  system.activationScripts.postActivation.text = ''
    # Free cmd+space for vicinae: turn off the Spotlight shortcut (symbolic
    # hotkey 64). -dict-add keeps every other hotkey as it is.
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # Never start the screen saver. It's a per-host setting, which nix-darwin
  # can't write but home-manager can.
  home-manager.users.${user}.targets.darwin.currentHostDefaults."com.apple.screensaver".idleTime = 0;
}
