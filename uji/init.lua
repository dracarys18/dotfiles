-- Default uji UI, configured via windows + buffers (nvim-style).
--
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
-- ~/.local/share/uji/uji-lock.json.
--
-- SECURITY: a pack is arbitrary code from the internet, executed on the next
-- start. Read what you install.
--
-- BREAKING: lua/plugins/*.lua no longer auto-sources. Move those files to
-- plugin/ (lua/ is for require() only).

-- Windows are laid out in priority order (default 50, lower first). For a
-- bottom split, lower priority sits closer to the bottom edge, so a plugin
-- can place itself without caring where its require() sits in this file.
uji.ui.open_win({ view = "messages", split = "top", size = "fill", wrap = true })
uji.ui.open_win({ view = "input", split = "bottom", size = "auto", border = "horizontal" })
uji.ui.open_win({ view = "modal", split = "bottom", size = "auto" })
local activity = uji.ui.open_win({ split = "bottom", size = 0, padding = 1 })

uji.ui.configure({
    input = { cursor_blink = true },
    suggest = { enabled = true, max_height = 5 },
    waiting = {
        loader = {
            frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
            interval_ms = 80,
        },
    },
})

-- Handlers run lowest-priority first and the first non-nil answer wins.
-- Pass { priority = n } to rule on a tool call before this one (default 50).
uji.on("tool_call", function(event)
    if event.name == "run_command" then
        local cmd = event.arguments.command or ""
        if string.match(cmd, "^rm %-rf") then
            return { deny = "Refusing to run rm -rf" }
        end
        return { ask = true }
    end
    -- reads and writes fall through to the default policy (allow / ask)
    return nil
end)

local waiting_text = "Working"

local function render_activity()
    if uji.status.state() == "working" then
        uji.ui.set_size(activity, 3)
        local elapsed = math.floor(uji.status.elapsed() or 0)
        uji.ui.set_lines(activity, {
            {
                { text = uji.status.loader_frame() .. " ", color = "cyan", bold = true },
                { text = waiting_text .. " (" .. elapsed .. "s)", color = "#808080" },
            },
        })
    else
        uji.ui.set_size(activity, 0)
    end
end

uji.on("status_changed", render_activity)
uji.on("tick", render_activity)

-- Keybindings. Every key is remappable per mode: normal, suggest, select,
-- prompt, confirm. A binding is either a builtin action name, a slash command
-- via { command = "models" }, or nil to unbind the key entirely.
--
-- Actions: quit, interrupt, submit, clear_input, backspace, cursor_left,
-- cursor_right, cursor_start, cursor_end, scroll_up, scroll_down, page_up,
-- page_down, scroll_top, scroll_bottom, modal_up, modal_down, modal_accept,
-- modal_cancel, suggest_complete, confirm_allow, confirm_deny, confirm_toggle,
-- nothing.
--
-- uji.keymap.set("normal", "<C-p>", { command = "models" })
-- uji.keymap.set("normal", "<C-u>", "clear_input")
-- uji.keymap.set("normal", "<C-c>", nil)
-- uji.keymap.list()

uji.keymap.set("normal", "<C-e>", { command = "effort" })

require("statusline").setup({})
require("planmode").setup({})
require("telescope").setup({ editor = "nvim" })
