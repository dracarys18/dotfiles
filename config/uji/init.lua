-- Config lives in ~/.config/uji (override with UJI_CONFIG_DIR):
--   init.lua        entry point, this file when you have none
--   lua/            module root; require("foo.bar") finds lua/foo/bar.lua
--                   or lua/foo/bar/init.lua
--   plugin/         *.lua here is sourced automatically after init.lua,
--                   sorted by name; number prefixes control order
--
-- Packs are extra directories with the same lua/ + plugin/ layout. Declaring
-- one clones it into ~/.local/share/uji/site if missing, then makes its
-- modules requirable and its plugin/ files auto-source:
--
--   uji.pack.add({
--     "user/repo",                      -- github shorthand
--     { "user/repo", tag = "v1.2" },    -- or branch = / commit =
--     { url = "https://git.sr.ht/~x/y" },
--     { dir = "~/code/my-plugin" },     -- local, never cloned
--   })
--   uji.pack.list()                     -- every root being searched
--
-- /sync updates installed packs and reloads. Versions are pinned in
-- ~/.config/uji/uji-lock.json.
--
-- SECURITY: a pack is arbitrary code from the internet, executed on the next
-- start. Read what you install.
--
-- BREAKING: lua/plugins/*.lua no longer auto-sources. Move those files to
-- plugin/ (lua/ is for require() only).

uji.tool.policy({
    default = "allow",
    run_command = { deny = { "/^\\s*rm\\s+-rf/" } },
    Bash = { deny = { "/^\\s*rm\\s+-rf/" } },
})

-- Keybindings. Every key is remappable per mode: normal, suggest, select,
-- prompt, confirm, overlay. A binding is either a builtin action name, a slash command
-- via { command = "models" }, or a function. uji.keymap.remove unbinds a key.
--
-- Actions: quit, interrupt, submit, clear_input, backspace, cursor_left,
-- cursor_right, cursor_start, cursor_end, scroll_up, scroll_down, page_up,
-- page_down, scroll_top, scroll_bottom, modal_up, modal_down, modal_accept,
-- modal_cancel, suggest_complete, confirm_allow, confirm_deny, confirm_toggle,
-- nothing.
--
-- uji.keymap.add("normal", "<C-p>", { command = "models" })
-- uji.keymap.add("normal", "<C-u>", "clear_input")
-- uji.keymap.remove("normal", "<C-c>")
-- uji.keymap.list()

uji.keymap.add("normal", "<C-e>", { command = "effort" })

uji.pack.add({ { dir = "~/Projects/uji-plugins" } })

require("statusline").setup({})
require("planmode").setup({})
require("telescope").setup({ editor = "nvim" })
require("websearch").setup({})
require("mcp").setup({})
require("skills").setup({ roots = { "~/Projects/uji-skills" } })
require("themes").setup({})
require("claude_code").setup({})
