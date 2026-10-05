# Tiling window manager and hotkeys, from nixpkgs. yabai's scripting
# addition needs SIP partly off (see `make bootstrap-mac`); nix-darwin then
# loads it at boot and keeps the sudoers rule matched to the exact binary.
{
  services.yabai = {
    enable = true;
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
      sudo yabai --load-sa
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"

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
