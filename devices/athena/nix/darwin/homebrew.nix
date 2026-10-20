{ config, ... }:
{
  # GUI apps only; every command-line tool comes from Nix. Anything not listed
  # here is uninstalled on every switch ("zap" also removes its app data).
  #
  # `brew bundle` cleanup runs `cargo uninstall` when it can see cargo during
  # activation. That is harmless now — cargo comes from Nix and no crates are
  # installed into ~/.cargo — but keep ~/.cargo empty/deleted so it stays so.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
    # Only things nixpkgs can't provide at all: 1Password, Sony's Remote Play,
    # Telegram's native Mac app and (until 8.30 lands) Signal. OBS, KDE Connect,
    # Vicinae and Ghostty have no darwin build in nixpkgs, so they are packaged
    # from their upstream DMGs in darwin/apps/ and installed by home-manager.
    # the taps come from nix-homebrew's flake inputs (darwin/default.nix), so
    # brew's tap list is the lockfile's tap list
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "1password"
      # 8.30.0: nixpkgs' 8.29.0 can't open a DB its schema 1830 migration
      # produced (see home/packages.nix). Self-updating, so it stays current.
      "signal"
      # a .pkg installer served from an unversioned url with `sha256: no_check`
      # upstream, so there is nothing worth pinning in Nix
      "sony-ps-remote-play"
      "telegram"
      # Nix bundles are adhoc-signed in versioned store paths, so TCC records
      # Screen Recording / Accessibility against a path that changes on every
      # update and the permission silently dies. Casks are upstream-signed at a
      # stable /Applications path, so it is granted once and survives.
      "vesktop" # screen recording, microphone
      "obs" # screen recording, camera, microphone
      "maccy" # accessibility (pastes into other apps)
      "vicinae" # accessibility (global hotkey, scripting)
      # everything else that ships its own app bundle, so none of it needs a
      # hand-written DMG derivation here
      "chatterino"
      "obsidian"
      "spotify"
      "kde-connect"
    ];
    # Mac App Store apps (needs you signed in to the App Store)
    masApps = {
      Developer = 640199958;
      TestFlight = 899247664;
    };
  };
}
