# Tiling window manager and hotkeys, from nixpkgs. yabai's scripting
# addition needs SIP partly off (see `make bootstrap-mac`); nix-darwin then
# loads it at boot and keeps the sudoers rule matched to the exact binary.
{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # TODO(macOS 27): temporary yabai build, remove once upstream supports macOS 27.
  #
  # yabai 7.1.25 (the last release) can't patch the macOS 27 Dock, so space
  # create/focus/destroy silently do nothing. This builds AhsanFazal's fork with
  # macOS 27 Dock patterns (pinned as `yabai-macos27` in flake.nix).
  # Track: https://github.com/asmvik/yabai/issues/2802 and /issues/2822
  #
  # It has landed when a yabai release newer than 7.1.25 mentions macOS 27 in
  # https://github.com/asmvik/yabai/blob/master/CHANGELOG.md and nixpkgs has
  # it: `nix eval --raw .#darwinConfigurations.mac.pkgs.yabai.version`
  # (after `nix flake update`). Then:
  #   1. delete this `let … in` block and the `package = yabai;` line below
  #   2. delete the `yabai-macos27` input from flake.nix, run `nix flake lock`
  #   3. `make switch`, and approve yabai in Accessibility again (new binary)
  #
  # Built with Apple's own clang (xcrun): the scripting addition is injected
  # into the Dock, so it must be arm64e, which nixpkgs' toolchain can't build
  # (nixpkgs#188322). Nix's build sandbox is off on macOS, so it's reachable.
  yabai = pkgs.stdenvNoCC.mkDerivation {
    pname = "yabai";
    version = "7.1.25-macos27";
    src = inputs.yabai-macos27;
    nativeBuildInputs = [ pkgs.installShellFiles ];
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      unset SDKROOT DEVELOPER_DIR MACOSX_DEPLOYMENT_TARGET
      # Apple's xcrun/make only for the build itself
      HOME=$TMPDIR PATH=${pkgs.xxd}/bin:/usr/bin:/bin:/usr/sbin:/sbin make install
      # the linker's minimal signature has no code requirement, so macOS can't
      # attach an Accessibility grant to it; give it a real ad-hoc signature
      /usr/bin/codesign --force --sign - --identifier com.asmvik.yabai bin/yabai
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp bin/yabai $out/bin/yabai
      installManPage doc/yabai.1
      runHook postInstall
    '';
    meta.mainProgram = "yabai";
  };
in
{
  services.yabai = {
    enable = true;
    package = yabai; # TODO(macOS 27): remove with the block above
    enableScriptingAddition = true;
    config = {
      layout = "bsp";
      window_placement = "second_child";
      window_gap = 0;
      split_ratio = "0.50";
      auto_balance = "on";
      window_animation_duration = "0.0";
    };
    extraConfig = ''
      # exact path: the sudo rule is tied to this binary
      sudo ${config.services.yabai.package}/bin/yabai --load-sa
      yabai -m signal --add event=dock_did_restart action="sudo ${config.services.yabai.package}/bin/yabai --load-sa"

      # always exactly 6 spaces
      space_count=$(yabai -m query --spaces | jq '. | length')
      while [ "$space_count" -lt 6 ]; do
          yabai -m space --create
          space_count=$((space_count + 1))
      done
      while [ "$space_count" -gt 6 ]; do
          yabai -m space --destroy "$space_count"
          space_count=$((space_count - 1))
      done

      yabai -m rule --add app="^(System Settings|Finder|Calculator|Archive Utility)$" manage=off

      yabai -m rule --add label=terminal app="^Ghostty$" space=1
      yabai -m rule --add label=browser  app="^Firefox$" space=2
      yabai -m rule --add label=cinny    app="^Cinny$"    space=3
      yabai -m rule --add label=signal   app="^Signal$"   space=3
      yabai -m rule --add label=discord  app="^Vesktop$"  space=3
      yabai -m rule --add label=telegram app="^Telegram$" space=3

      # OBS gets the last regular space, labelled "obs"
      normal_spaces() { yabai -m query --spaces | jq '[.[] | select(."is-native-fullscreen" | not)]'; }
      [ "$(normal_spaces | jq length)" -lt 3 ] && yabai -m space --create
      yabai -m space "$(normal_spaces | jq '.[-1].index')" --label obs
      yabai -m rule --add label=obs app="^OBS Studio$" space=obs

      yabai -m rule --apply
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # --- Window Actions ---
      rctrl + shift - q : skhd -k "cmd - q"
      alt + shift - q   : skhd -k "cmd - q"

      # yabai's fullscreen, not macOS's: native fullscreen breaks hover and
      # clicks in Firefox, and with the menu bar and Dock hidden it looks the same
      rctrl + shift - f : yabai -m window --toggle zoom-fullscreen
      alt + shift - f   : yabai -m window --toggle zoom-fullscreen

      rctrl - space : yabai -m window --toggle float
      alt - space   : yabai -m window --toggle float

      # --- Move between spaces ---
      rctrl - 1 : yabai -m space --focus 1
      alt - 1   : yabai -m space --focus 1

      rctrl - 2 : yabai -m space --focus 2
      alt - 2   : yabai -m space --focus 2

      rctrl - 3 : yabai -m space --focus 3
      alt - 3   : yabai -m space --focus 3

      rctrl - 4 : yabai -m space --focus 4
      alt - 4   : yabai -m space --focus 4

      rctrl - 5 : yabai -m space --focus 5
      alt - 5   : yabai -m space --focus 5

      rctrl - 6 : yabai -m space --focus 6
      alt - 6   : yabai -m space --focus 6

      rctrl - 7 : yabai -m space --focus 7
      alt - 7   : yabai -m space --focus 7

      rctrl - 8 : yabai -m space --focus 8
      alt - 8   : yabai -m space --focus 8

      rctrl - 9 : yabai -m space --focus 9
      alt - 9   : yabai -m space --focus 9

      # --- Open Apps ---
      rctrl + shift - g : open -a "Ghostty"
      alt + shift - g   : open -a "Ghostty"

      rctrl + shift - z : open -a "Firefox"
      alt + shift - z   : open -a "Firefox"

      rctrl + shift - c : open -a "Cinny"
      alt + shift - c   : open -a "Cinny"

      rctrl + shift - s : open -a "Signal"
      alt + shift - s   : open -a "Signal"

      rctrl + shift - d : open -a "Vesktop"
      alt + shift - d   : open -a "Vesktop"

      rctrl + shift - t : open -a "Telegram"
      alt + shift - t   : open -a "Telegram"

      rctrl + shift - p : open -a "Spotify"
      alt + shift - p   : open -a "Spotify"

      rctrl + shift - o : open -a "OBS"
      alt + shift - o   : open -a "OBS"

      # --- Send focused window to space (and follow) ---
      rctrl + shift - 1 : yabai -m window --space 1; yabai -m space --focus 1
      alt + shift - 1   : yabai -m window --space 1; yabai -m space --focus 1

      rctrl + shift - 2 : yabai -m window --space 2; yabai -m space --focus 2
      alt + shift - 2   : yabai -m window --space 2; yabai -m space --focus 2

      rctrl + shift - 3 : yabai -m window --space 3; yabai -m space --focus 3
      alt + shift - 3   : yabai -m window --space 3; yabai -m space --focus 3

      rctrl + shift - 4 : yabai -m window --space 4; yabai -m space --focus 4
      alt + shift - 4   : yabai -m window --space 4; yabai -m space --focus 4

      rctrl + shift - 5 : yabai -m window --space 5; yabai -m space --focus 5
      alt + shift - 5   : yabai -m window --space 5; yabai -m space --focus 5

      rctrl + shift - 6 : yabai -m window --space 6; yabai -m space --focus 6
      alt + shift - 6   : yabai -m window --space 6; yabai -m space --focus 6

      rctrl + shift - 7 : yabai -m window --space 7; yabai -m space --focus 7
      alt + shift - 7   : yabai -m window --space 7; yabai -m space --focus 7

      rctrl + shift - 8 : yabai -m window --space 8; yabai -m space --focus 8
      alt + shift - 8   : yabai -m window --space 8; yabai -m space --focus 8

      rctrl + shift - 9 : yabai -m window --space 9; yabai -m space --focus 9
      alt + shift - 9   : yabai -m window --space 9; yabai -m space --focus 9

      # --- Swap window in direction (WASD) ---
      rctrl + cmd - a : yabai -m window --swap west
      alt + cmd - a   : yabai -m window --swap west

      rctrl + cmd - s : yabai -m window --swap south
      alt + cmd - s   : yabai -m window --swap south

      rctrl + cmd - w : yabai -m window --swap north
      alt + cmd - w   : yabai -m window --swap north

      rctrl + cmd - d : yabai -m window --swap east
      alt + cmd - d   : yabai -m window --swap east

      # --- Warp window in direction (reflow into tree, HJKL) ---
      rctrl + cmd - h : yabai -m window --warp west
      alt + cmd - h   : yabai -m window --warp west

      rctrl + cmd - j : yabai -m window --warp south
      alt + cmd - j   : yabai -m window --warp south

      rctrl + cmd - k : yabai -m window --warp north
      alt + cmd - k   : yabai -m window --warp north

      rctrl + cmd - l : yabai -m window --warp east
      alt + cmd - l   : yabai -m window --warp east

      # --- Resize (grow/shrink east edge, WASD-ish) ---
      rctrl + shift - h : yabai -m window --resize left:-40:0
      alt + shift - h   : yabai -m window --resize left:-40:0

      rctrl + shift - l : yabai -m window --resize left:40:0
      alt + shift - l   : yabai -m window --resize left:40:0

      rctrl + shift - k : yabai -m window --resize bottom:0:-40
      alt + shift - k   : yabai -m window --resize bottom:0:-40

      rctrl + shift - j : yabai -m window --resize bottom:0:40
      alt + shift - j   : yabai -m window --resize bottom:0:40

      # --- Balance / rotate layout ---
      rctrl - e : yabai -m space --balance
      alt - e   : yabai -m space --balance

      rctrl - r : yabai -m space --rotate 90
      alt - r   : yabai -m space --rotate 90

      # --- Slack ---
      rctrl + shift - m : open -a "Slack"
      alt + shift - m   : open -a "Slack"

      # --- Window Focus (Vim-ish HJKL or WASD) ---
      rctrl - a : yabai -m window --focus west
      alt - a   : yabai -m window --focus west

      rctrl - s : yabai -m window --focus south
      alt - s   : yabai -m window --focus south

      rctrl - w : yabai -m window --focus north
      alt - w   : yabai -m window --focus north

      rctrl - d : yabai -m window --focus east
      alt - d   : yabai -m window --focus east
    '';
  };
  # skhd runs every hotkey command through $SHELL; pin one that always exists
  launchd.user.agents.skhd.serviceConfig.EnvironmentVariables.SHELL = "/bin/bash";
}
