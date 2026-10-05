# Neovim, configured in Nix with nixvim. Imported by ../default.nix as
# programs.nixvim.imports, so these are nixvim modules (not home-manager ones).
{
  imports = [
    ./options.nix
    ./autocmds.nix
    ./keymaps.nix
    ./colorscheme.nix
    ./plugins/ui.nix
    ./plugins/editor.nix
    ./plugins/telescope.nix
    ./plugins/completion.nix
    ./plugins/lsp.nix
    ./plugins/treesitter.nix
    ./plugins/lang.nix
    ./plugins/dap.nix
  ];
}
