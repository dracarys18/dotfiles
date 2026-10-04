local parsers = {
    'c', 'rust', 'terraform', 'toml', 'lua', 'json', 'python',
    'cmake', 'make', 'typescript', 'bash', 'cpp', 'css', 'fish',
    'html', 'vim', 'yaml', 'go', 'gomod', 'gowork', 'zig', 'ocaml',
    'markdown', 'markdown_inline', 'typst',
}

require('nvim-treesitter').setup {}
vim.schedule(function()
    require('nvim-treesitter').install(parsers)
end)
