-- Enhanced snacks.nvim configuration with "everything" search

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
        -- Define a custom "all" picker that searches everything
        multi = {
          enabled = true,
          default = "all",
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

      -- Everything search - files + grep combined
      maps.n["<Leader>ff"] = {
        function()
          require("snacks").picker.files()
        end,
        desc = "Search files (with live grep fallback)",
      }
      -- Alternative: grep for text search
      maps.n["<Leader>fg"] = {
        function()
          require("snacks").picker.grep()
        end,
        desc = "Grep search in files",
      }
    end,
  },
}
