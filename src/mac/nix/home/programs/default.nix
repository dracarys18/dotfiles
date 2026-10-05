# One file per tool, using home-manager's module for it
{
  imports = [
    ./1password.nix
    ./bat.nix
    ./direnv.nix
    ./eza.nix
    ./fish.nix
    ./fzf.nix
    ./ghostty.nix
    ./git.nix
    ./starship.nix
    ./tmux.nix
    ./vesktop.nix
    ./zoxide.nix
  ];
}
