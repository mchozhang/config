-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- font
config.font_size = 16

-- move cursor
local act = wezterm.action

config.keys = {
  -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
  { key = 'LeftArrow', mods = 'OPT', action = act.SendString '\x1bb' },
  -- Make Option-Right equivalent to Alt-f; forward-word
  { key = 'RightArrow', mods = 'OPT', action = act.SendString '\x1bf' },
  -- Move cursor to start/end of line
  { key = 'LeftArrow', mods = 'CMD', action = act.SendKey { key = 'Home' }},
  { key = 'RightArrow', mods = 'CMD', action = act.SendKey { key = 'End' }},
  { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
}

config.hyperlink_rules = {}

-- and finally, return the configuration to wezterm
return config
