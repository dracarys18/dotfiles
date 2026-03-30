require('nvim-treesitter.configs').setup {
    ensure_installed = {
        'c', 'rust', 'terraform', 'toml', 'lua', 'json', 'python',
        'cmake', 'make', 'typescript', 'bash', 'cpp', 'css', 'fish',
        'html', 'vim', 'yaml', 'go', 'gomod', 'gowork', 'zig', 'ocaml',
    },
    highlight = {
        enable                            = true,
        additional_vim_regex_highlighting = false,
    },
}
