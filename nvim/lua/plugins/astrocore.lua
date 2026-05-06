-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      features = {
        large_buf = { size = 1024 * 256, lines = 10000 },
        autopairs = true,
        cmp = true,
        diagnostics = { virtual_text = false, virtual_lines = true },
        highlighturl = true,
        notifications = true,
      },
      diagnostics = {
        virtual_text = false,
        underline = true,
      },
      options = {
        opt = {
          relativenumber = false,
          number = true,
          spell = false,
          signcolumn = "yes:1",
          wrap = true,
        },
        g = {},
      },
      mappings = {
        n = {
          ["0"] = { "g0", desc = "Navigate wrapped line start" },
          ["$"] = { "g$", desc = "Navigate wrapped line end" },
          ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
          ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
          ["<Leader>bd"] = {
            function()
              require("astroui.status.heirline").buffer_picker(
                function(bufnr) require("astrocore.buffer").close(bufnr) end
              )
            end,
            desc = "Close buffer from tabline",
          },
          ["\\"] = false,
        },
      },
    },
  },
  {
    "AstroNvim/astroui",
    opts = {
      colorscheme = "kanagawa",
      icons = {
        LSPLoading1 = "⠋",
        LSPLoading2 = "⠙",
        LSPLoading3 = "⠹",
        LSPLoading4 = "⠸",
        LSPLoading5 = "⠼",
        LSPLoading6 = "⠴",
        LSPLoading7 = "⠦",
        LSPLoading8 = "⠧",
        LSPLoading9 = "⠇",
        LSPLoading10 = "⠏",
      },
    },
  },
}
