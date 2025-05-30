-- local lspstatus = require('lsp-status')
-- lspstatus.register_progress()

require 'lsp.lua-language-server'
require 'lsp.clangd'

local lspconfig = require 'lspconfig'
local lspstatus = require 'lsp-status'
local coq = require 'coq'

require 'lspconfig'.ts_ls.setup {}
require 'lspconfig'.sqlls.setup {}
require 'lspconfig'.gopls.setup {}
require 'lspconfig'.zls.setup {}
-- require'lspconfig'.jsonls.setup {
--     settings = {
--         json = {
--             schemas = require('schemastore').json.schemas(),
--             validate = { enable = true },
--         },
--     },
-- }

-- Set completeopt to have a better completion experience
-- vim.o.completeopt= "menuone,noinsert,noselect"
vim.o.completeopt = "menuone,noselect"
vim.o.clipboard = "unnamedplus"

-- vim.api.nvim_command [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
-- vim.api.nvim_command [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
-- vim.api.nvim_command [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]
--
vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
-- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')


require('mason-lspconfig').setup_handlers({
    function(server_name)
        if server_name ~= "rust_analyzer" then
            lspconfig[server_name].setup({
                on_attach = lspstatus.on_attach,
                capabilities = coq.lsp_ensure_capabilities(lspstatus.capabilities),
            })
        end
    end,
})


require("bufferline").setup {
    options = { diagnostics = "nvm_lsp" },
}
