-- Enhanced snacks.nvim configuration with "everything" search

local function everything_search()
  local Snacks = require("snacks")
  -- Default to "All" search - files + recent + buffers combined
  Snacks.picker.files({
    auto_confirm = false,
  })
end

---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      picker = {
        enabled = true,
        sources = {
          files = {
            exclude = {
              ".git",
              "node_modules",
              ".venv",
              "__pycache__",
              ".pytest_cache",
            },
          },
        },
        formatters = {
          file = {
            filename_only = true,
            truncate = 80,
          },
        },
      },
    },
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      local maps = opts.mappings
      maps.n = maps.n or {}

      -- Everything search with filter menu
      maps.n["<Leader>ff"] = {
        everything_search,
        desc = "Everything search (files, grep, buffers, recent)",
      }
    end,
  },
}
