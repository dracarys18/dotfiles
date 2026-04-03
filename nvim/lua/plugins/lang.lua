-- go.nvim (rustaceanvim, zig.vim, d2-vim auto-configure via their plugin/ files)
-- textobjects=false: go.nvim's default (true) calls configs.setup({textobjects=...})
-- which overwrites nvim-treesitter highlight config (configs.setup is not additive)
require('go').setup({
    lsp_goimports = true,
    textobjects   = false,
})
