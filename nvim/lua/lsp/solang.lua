local lspconfig = require 'lspconfig'
local lspstatus = require 'lsp-status'
local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.solang.setup {
    on_attach = function(client) lspstatus.on_attach(client) end,
    capabilities = capabilities
}
