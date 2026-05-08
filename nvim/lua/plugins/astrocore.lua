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
        virtual_text = true,
        underline = true,
      },
      options = {
        opt = {
          relativenumber = false,
          number = true,
          spell = false,
          signcolumn = "yes:1",
          wrap = true,
          guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr:hor20,o:hor50",
        },
        g = {
          vimtex_syntax_nospell_comments = 1,
        },
      },
      autocmds = {
        kanagawa_cursor = {
          {
            event = "ColorScheme",
            pattern = "kanagawa*",
            callback = function()
              -- lotusInk1 (#545464) is too gray; use near-black for contrast on lotus cream
              vim.api.nvim_set_hl(0, "Cursor", { bg = "#1F1F28", fg = "#DCD7BA" })
            end,
          },
        },
        no_scroll_past_eof = {
          {
            event = "WinScrolled",
            callback = function()
              local win = vim.api.nvim_get_current_win()
              local info = vim.fn.getwininfo(win)[1]
              local last_line = vim.fn.line("$")
              local ideal_topline = math.max(1, last_line - info.height + 1)
              if info.topline > ideal_topline then vim.fn.winrestview({ topline = ideal_topline }) end
            end,
          },
        },
        clock_refresh = {
          {
            event = "VimEnter",
            callback = function()
              vim.uv.new_timer():start(
                (60 - tonumber(os.date "%S")) * 1000,
                60000,
                vim.schedule_wrap(function() vim.cmd.redrawstatus() end)
              )
            end,
          },
        },
        tex_prose = {
          {
            event = "FileType",
            pattern = "tex",
            desc = "Prose settings for LaTeX",
            callback = function()
              vim.opt_local.spell = true
              vim.opt_local.spelllang = "en_us"
              vim.opt_local.linebreak = true
              vim.opt_local.breakindent = true
              vim.opt_local.showbreak = "↪ "
            end,
          },
        },
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
