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
      # NOT "zap": zap also deletes each removed cask's app data. When Firefox
      # stopped being a cask, `brew bundle` moved ~/Library/Application
      # Support/Firefox to the Trash and Firefox came up as a fresh install.
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
    };
    # Every GUI app is a cask. The reason is TCC: Nix bundles are adhoc-signed
    # inside versioned store paths, so screen recording / camera / microphone /
    # accessibility grants die on each update. Casks are upstream-signed at a
    # stable /Applications path and are granted once.
    #
    # No formulae on purpose. nix-homebrew pins brew itself (brew-src in
    # flake.lock), while the tap inputs move with `make update`; a formula that
    # uses newer DSL then fails against the older brew, e.g. mpv's dav1d
    # dependency: "undefined method 'new' for an instance of Symbol".
    # mpv therefore stays in home/packages.nix.
    brews = [ ];
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
      "ghostty"
    ];
    # Mac App Store apps (needs you signed in to the App Store)
    masApps = {
      Developer = 640199958;
      TestFlight = 899247664;
    };
  };
}
