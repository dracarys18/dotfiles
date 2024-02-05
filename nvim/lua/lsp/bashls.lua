local lspconfig = require'lspconfig'
local lspstatus = require('lsp-status')
local coq = require'coq'

lspconfig.bashls.setup{
    cmd = { "bash-language-server", "start" },
    on_attach=function(client) lspstatus.on_attach(client)  return end,
    capabilities = coq.lsp_ensure_capabilities(lspstatus.capabilities),
    filetypes = { "sh" },
}

