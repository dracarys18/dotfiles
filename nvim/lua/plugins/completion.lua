require('blink.cmp').setup {
    keymap = {
        preset   = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
    },
    appearance = { nerd_font_variant = 'mono' },
    sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets', 'copilot' },
        providers = {
            copilot = {
                name = "copilot",
                module = "blink-copilot",
                score_offset = 100,
                async = true,
            },
        },
    },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    signature = { enabled = true },
}
