# uji, the coding agent, with the home-manager modules from its flakes. Both
# repos are private (SSH), so the bootstrap switch leaves uji out entirely.
{ inputs, withUji, ... }:

{
  imports =
    if withUji then
      [
        inputs.uji.homeModules.default
        inputs.uji-plugins.homeModules.default
        ./settings.nix
        ./litellm.nix
        ./todo.nix
      ]
    else
      [ ];
}
