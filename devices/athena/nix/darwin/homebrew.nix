{
  # GUI apps only; every command-line tool comes from Nix. Anything not listed
  # here is uninstalled on every switch ("zap" also removes its app data).
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
