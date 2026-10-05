{
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
        name = "tsirysndr/tap";
        trusted = true;
      }
    ];
    brews = [
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
}
