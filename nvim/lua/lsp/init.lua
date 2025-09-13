-- local lspstatus = require('lsp-status')
-- lspstatus.register_progress()

require 'lsp.lua-language-server'
require 'lsp.clangd'

local lspconfig = require 'lspconfig'
local lspstatus = require 'lsp-status'
local capabilities = require('cmp_nvim_lsp').default_capabilities()


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

local function starts_with(str, start)
    return str:sub(1, #start) ~= start
end

require('mason-lspconfig').setup({
    function(server_name)
        if starts_with(server_name, "rust") then
            lspconfig[server_name].setup({
                on_attach = lspstatus.on_attach,
                capabilities = capabilities
            })
        end
    end,
})

require 'lspconfig'.zls.setup {
    on_attach = lspstatus.on_attach,
    capabilities = capabilities,
    settings = {
        zls = {
            enable_build_on_save = true,
            semantic_tokens = "partial"
        }
    }
}

require("bufferline").setup {
    options = { diagnostics = "nvm_lsp" },
}
