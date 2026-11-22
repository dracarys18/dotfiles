{
  config,
  pkgs,
  inputs,
  ...
}:

let
  yabai = pkgs.stdenvNoCC.mkDerivation {
    pname = "yabai";
    version = "7.1.25-macos27";
    src = inputs.yabai-macos27;
    nativeBuildInputs = [ pkgs.installShellFiles ];
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      unset SDKROOT DEVELOPER_DIR MACOSX_DEPLOYMENT_TARGET
      HOME=$TMPDIR PATH=${pkgs.xxd}/bin:/usr/bin:/bin:/usr/sbin:/sbin make install
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
      sudo ${config.services.yabai.package}/bin/yabai --load-sa
      yabai -m signal --add event=dock_did_restart action="sudo ${config.services.yabai.package}/bin/yabai --load-sa"

      normal_spaces() { yabai -m query --spaces | jq '[.[] | select(."is-native-fullscreen" | not)]'; }
      space_count=$(normal_spaces | jq length)
      while [ "$space_count" -lt 6 ]; do
          yabai -m space --create
          space_count=$((space_count + 1))
      done
      while [ "$space_count" -gt 6 ]; do
          yabai -m space --destroy "$(normal_spaces | jq '.[-1].index')"
          space_count=$((space_count - 1))
      done

      yabai -m rule --add app="^(System Settings|Finder|Calculator|Archive Utility)$" manage=off

      yabai -m rule --add label=terminal app="^Ghostty$" space=1
      yabai -m rule --add label=browser  app="^Firefox$" space=2
      yabai -m rule --add label=signal   app="^Signal$"   space=3
      yabai -m rule --add label=discord  app="^Vesktop$"  space=3
      yabai -m rule --add label=telegram app="^Telegram$" space=3

      [ "$(normal_spaces | jq length)" -lt 3 ] && yabai -m space --create
      yabai -m space "$(normal_spaces | jq '.[-1].index')" --label obs
      yabai -m rule --add label=obs app="^OBS Studio$" space=obs

      yabai -m rule --apply
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      rctrl + shift - q : skhd -k "cmd - q"
      alt + shift - q   : skhd -k "cmd - q"

      rctrl + shift - f : yabai -m window --toggle native-fullscreen
      alt + shift - f   : yabai -m window --toggle native-fullscreen

      rctrl - space : yabai -m window --toggle float
      alt - space   : yabai -m window --toggle float

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

      rctrl + shift - g : open -a "/Applications/Ghostty.app"
      alt + shift - g   : open -a "/Applications/Ghostty.app"

      rctrl + shift - z : open -a "$HOME/Applications/Home Manager Apps/Firefox.app"
      alt + shift - z   : open -a "$HOME/Applications/Home Manager Apps/Firefox.app"

      rctrl + shift - s : open -a "/Applications/Signal.app"
      alt + shift - s   : open -a "/Applications/Signal.app"

      rctrl + shift - d : open -a "/Applications/Vesktop.app"
      alt + shift - d   : open -a "/Applications/Vesktop.app"

      rctrl + shift - t : open -a "/Applications/Telegram.app"
      alt + shift - t   : open -a "/Applications/Telegram.app"

      rctrl + shift - o : open -a "/Applications/OBS.app"
      alt + shift - o   : open -a "/Applications/OBS.app"

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

      rctrl + cmd - a : yabai -m window --swap west
      alt + cmd - a   : yabai -m window --swap west

      rctrl + cmd - s : yabai -m window --swap south
      alt + cmd - s   : yabai -m window --swap south

      rctrl + cmd - w : yabai -m window --swap north
      alt + cmd - w   : yabai -m window --swap north

      rctrl + cmd - d : yabai -m window --swap east
      alt + cmd - d   : yabai -m window --swap east

      rctrl + cmd - h : yabai -m window --warp west
      alt + cmd - h   : yabai -m window --warp west

      rctrl + cmd - j : yabai -m window --warp south
      alt + cmd - j   : yabai -m window --warp south

      rctrl + cmd - k : yabai -m window --warp north
      alt + cmd - k   : yabai -m window --warp north

      rctrl + cmd - l : yabai -m window --warp east
      alt + cmd - l   : yabai -m window --warp east

      rctrl + shift - h : yabai -m window --resize left:-40:0
      alt + shift - h   : yabai -m window --resize left:-40:0

      rctrl + shift - l : yabai -m window --resize left:40:0
      alt + shift - l   : yabai -m window --resize left:40:0

      rctrl + shift - k : yabai -m window --resize bottom:0:-40
      alt + shift - k   : yabai -m window --resize bottom:0:-40

      rctrl + shift - j : yabai -m window --resize bottom:0:40
      alt + shift - j   : yabai -m window --resize bottom:0:40

      rctrl - e : yabai -m space --balance
      alt - e   : yabai -m space --balance

      rctrl - r : yabai -m space --rotate 90
      alt - r   : yabai -m space --rotate 90

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
  launchd.user.agents.skhd.serviceConfig.EnvironmentVariables.SHELL = "/bin/bash";
}
