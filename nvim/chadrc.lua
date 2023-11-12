---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

M.ui = {
  theme = "kanagawa",
  theme_toggle = { "kanagawa", "one_light" },

  hl_override = highlights.override,
  hl_add = highlights.add,
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

-- this removes the tab close button
M.ui = {
  tabufline = {
    overriden_modules = function(modules)
      table.remove(modules, 4)
    end,
  },
}

return M
