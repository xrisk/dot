-- Enhanced snacks.nvim configuration with "everything" search

local function everything_search()
  local Snacks = require("snacks")
  vim.ui.select(
    { "Files", "Grep", "Buffers", "Recent Files", "All" },
    { prompt = "Search: " },
    function(choice)
      if not choice then return end
      if choice == "Files" then
        Snacks.picker.files()
      elseif choice == "Grep" then
        Snacks.picker.grep()
      elseif choice == "Buffers" then
        Snacks.picker.buffers()
      elseif choice == "Recent Files" then
        Snacks.picker.recent()
      elseif choice == "All" then
        -- Search files + recent + buffers combined
        Snacks.picker.files({
          auto_confirm = false,
          includeBuffers = true,
          includeRecent = true,
        })
      end
    end
  )
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
