require('copilot').setup {
    suggestion = {
        enabled      = true,
        auto_trigger = true,
        keymap = {
            accept  = '<Tab>',
            next    = '<M-]>',
            prev    = '<M-[>',
            dismiss = '<M-e>',
        },
    },
    panel      = { enabled = false },
    filetypes  = {
        rust  = true,
        go    = true,
        zig   = true,
        ml    = true,
        ['*'] = false,
    },
}
