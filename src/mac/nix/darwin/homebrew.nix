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
    # Everything here is missing from nixpkgs (1Password, Sony, Telegram's
    # native Mac app) or not available for macOS in nixpkgs
    # (ghostty, kde-connect, obs, vicinae). Command-line tools, Firefox,
    # Signal, Spotify, Vesktop, Maccy and Jellyfin come from Nix.
    casks = [
      "1password"
      "ghostty"
      "kde-connect"
      "obs"
      "sony-ps-remote-play"
      "telegram"
      "vicinae"
    ];
    # Mac App Store apps (needs you signed in to the App Store)
    masApps = {
      Developer = 640199958;
      TestFlight = 899247664;
    };
  };
}
