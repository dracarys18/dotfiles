local lspconfig = require 'lspconfig'
local lspstatus = require 'lsp-status'

local capabilities = require('cmp_nvim_lsp').default_capabilities()
lspconfig.denols.setup {
    on_attach = function(client)
        lspstatus.on_attach(client)
        return
    end,
    capabilities = capabilities
}
