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

  system.activationScripts.postActivation.text = ''
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
  '';
}
