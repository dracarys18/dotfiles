local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.font = wezterm.font_with_fallback { "Hasklug Nerd Font", "Hasklug Nerd Font Mono" }
config.color_scheme = 'Oxocarbon Dark'
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.default_cursor_style = "BlinkingBlock"
config.window_background_opacity = 0.9
config.cursor_blink_rate = 8
config.initial_cols = 120
config.font_size = 14

config.window_padding = {
    top = 0,
    left = 0,
    right = 0,
    bottom = 0,
}
config.use_ime = false


return config
