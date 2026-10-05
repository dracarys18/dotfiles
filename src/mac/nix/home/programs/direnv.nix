{
  # `cd` into a project with a flake + `.envrc` (`use flake`) and its dev shell
  # loads; nix-direnv caches it so it's instant after the first time
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
