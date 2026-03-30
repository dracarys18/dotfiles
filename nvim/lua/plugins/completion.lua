require('blink.cmp').setup {
    keymap = {
        preset  = 'default',
        ['<CR>']  = { 'accept', 'fallback' },
    },
    appearance = { nerd_font_variant = 'mono' },
    sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets' },
    },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    signature = { enabled = true },
}
