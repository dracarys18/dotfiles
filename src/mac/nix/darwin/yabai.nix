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
    skhdConfig = builtins.readFile ../../config/yabai/skhdrc;
  };
  # skhd runs every hotkey command through $SHELL; pin one that always exists
  launchd.user.agents.skhd.serviceConfig.EnvironmentVariables.SHELL = "/bin/bash";
}
