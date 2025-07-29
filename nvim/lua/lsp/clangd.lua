local lspconfig = require 'lspconfig'
local lspstatus = require 'lsp-status'
local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.clangd.setup {
    capabilities = capabilities,
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
    single_file_support = true,
}
