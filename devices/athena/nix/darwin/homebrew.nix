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
    casks = [
      "1password"
      # 8.30.0: nixpkgs' 8.29.0 can't open a DB its schema 1830 migration
      # produced (see home/packages.nix). Self-updating, so it stays current.
      "signal"
      # a .pkg installer served from an unversioned url with `sha256: no_check`
      # upstream, so there is nothing worth pinning in Nix
      "sony-ps-remote-play"
      "telegram"
    ];
    # Mac App Store apps (needs you signed in to the App Store)
    masApps = {
      Developer = 640199958;
      TestFlight = 899247664;
    };
  };
}
