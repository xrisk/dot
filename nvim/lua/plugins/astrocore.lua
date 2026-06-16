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
        autopairs = false,
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
          viewoptions = "cursor,curdir",
          autoread = true,
        },
        g = {
          vimtex_syntax_nospell_comments = 1,
        },
      },
      autocmds = {
        auto_reload = {
          {
            event = { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" },
            pattern = "*",
            callback = function()
              if vim.fn.mode() ~= "c" then vim.cmd "checktime" end
            end,
          },
        },
        fold_persistence = {
          {
            event = "BufWinLeave",
            pattern = "?*",
            callback = function()
              local bt = vim.bo.buftype
              if bt == "" or bt == "acwrite" then vim.cmd "silent! mkview" end
            end,
          },
          {
            event = "BufWinEnter",
            pattern = "?*",
            callback = function()
              local bt = vim.bo.buftype
              if bt == "" or bt == "acwrite" then vim.cmd "silent! loadview" end
            end,
          },
        },
        fold_state = {
          {
            event = "BufWinLeave",
            pattern = "?*",
            callback = function()
              local bt = vim.bo.buftype
              if bt ~= "" and bt ~= "acwrite" then return end
              local path = vim.fn.expand "%:p"
              if path == "" then return end
              local closed = {}
              for i = 1, vim.fn.line "$" do
                if vim.fn.foldclosed(i) == i then table.insert(closed, i) end
              end
              local dir = vim.fn.stdpath "state" .. "/fold_state/"
              vim.fn.mkdir(dir, "p")
              local f = io.open(dir .. vim.fn.sha256(path), "w")
              if f then
                f:write(vim.json.encode(closed))
                f:close()
              end
            end,
          },
          {
            event = "BufWinEnter",
            pattern = "?*",
            callback = function()
              local bt = vim.bo.buftype
              if bt ~= "" and bt ~= "acwrite" then return end
              local path = vim.fn.expand "%:p"
              if path == "" then return end
              local dir = vim.fn.stdpath "state" .. "/fold_state/"
              local f = io.open(dir .. vim.fn.sha256(path), "r")
              if not f then return end
              local content = f:read "*a"
              f:close()
              local ok, closed = pcall(vim.json.decode, content)
              if not ok or not closed or #closed == 0 then return end
              local bufnr = vim.api.nvim_get_current_buf()
              vim.defer_fn(function()
                if not vim.api.nvim_buf_is_valid(bufnr) then return end
                for _, lnum in ipairs(closed) do
                  pcall(vim.cmd, lnum .. "foldclose")
                end
              end, 150)
            end,
          },
        },
        kanagawa_cursor = {
          {
            event = "ColorScheme",
            pattern = "kanagawa*",
            callback = function()
              -- lotusInk1 (#545464) is too gray; use near-black for contrast on lotus cream
              vim.api.nvim_set_hl(0, "Cursor", { bg = "#1F1F28", fg = "#DCD7BA" })
              -- distinguish \texttt{} concealed text with the terminal's ANSI blue
              vim.api.nvim_set_hl(0, "texStyleArgConc", { fg = "#4d699b" })
            end,
          },
        },
        -- no_scroll_past_eof = {
        --   {
        --     event = "WinScrolled",
        --     callback = function()
        --       local win = vim.api.nvim_get_current_win()
        --       local info = vim.fn.getwininfo(win)[1]
        --       local last_line = vim.fn.line("$")
        --       local ideal_topline = math.max(1, last_line - info.height + 1)
        --       if info.topline > ideal_topline then vim.fn.winrestview({ topline = ideal_topline }) end
        --     end,
        --   },
        -- },
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
        stop_jobs_on_quit = {
          {
            event = "QuitPre",
            callback = function()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buf].buftype == "terminal" then
                  local job_id = vim.b[buf].terminal_job_id
                  if job_id then pcall(vim.fn.jobstop, job_id) end
                end
              end
            end,
          },
        },
        vimtex_thesis = {
          {
            event = "VimLeavePre",
            callback = function()
              if vim.fn.getcwd():find(vim.fn.expand "~" .. "/thesis", 1, true) then pcall(vim.cmd, "VimtexStop") end
            end,
          },
        },
        tex_prose = {
          {
            event = "FileType",
            pattern = "tex",
            desc = "Prose settings for LaTeX",
            callback = function()
              vim.b.minuet_virtual_text_auto_trigger = true
              vim.opt_local.spell = true
              vim.opt_local.spelllang = "en_us"
              vim.opt_local.linebreak = true
              vim.opt_local.breakindent = true
              vim.opt_local.showbreak = "↪ "
              vim.opt_local.foldmethod = "expr"
              vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
              vim.opt_local.foldlevel = 99
              vim.opt_local.foldenable = true
              -- Syntax conceal: \footnote{content} → \footnote{·}
              -- Works for both single-line and multi-line footnotes.
              -- texFnInner handles arbitrarily nested braces so the outer end=} matches
              -- the correct closing brace of \footnote.
              -- vim.opt_local.conceallevel = 0
              -- vim.opt_local.concealcursor = "n"
              -- vim.cmd [[
              --   syn region texFnContent
              --     \ start=+\\footnote{+
              --     \ end=+}+
              --     \ conceal cchar=·
              --     \ contains=texFnInner
              --     \ containedin=ALL
              --   syn region texFnInner
              --     \ start=+{+
              --     \ end=+}+
              --     \ contained
              --     \ contains=texFnInner
              --     \ transparent
              -- ]]
              --
              -- vim.keymap.set(
              --   "n",
              --   "<LocalLeader>zf",
              --   function() vim.opt_local.conceallevel = vim.opt_local.conceallevel:get() == 0 and 2 or 0 end,
              --   { buffer = true, desc = "Toggle footnote conceal" }
              -- )
            end,
          },
        },
      },
      mappings = {
        n = {
          ["<Leader>fw"] = {
            function()
              require("snacks").picker.grep {
                sort = function(a, b)
                  local a_pri = a.file and a.file:match "^sections/.*%.tex$" ~= nil
                  local b_pri = b.file and b.file:match "^sections/.*%.tex$" ~= nil
                  if a_pri ~= b_pri then return a_pri end
                  if a.score ~= b.score then return a.score > b.score end
                  return a.idx < b.idx
                end,
              }
            end,
            desc = "Find words",
          },
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
      colorscheme = "kanagawa-lotus",
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
