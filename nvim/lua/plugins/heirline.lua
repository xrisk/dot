return {
  "rebelot/heirline.nvim",
  dependencies = {
    "skwee357/nvim-prose",
  },
  opts = function(_, opts)
    local status = require "astroui.status"
    local prose = require "nvim-prose"

    local tc_cache = { result = "", tick = -1, file = "" }
    local tc_running = false

    local vimtex_state = nil
    local vtex_group = vim.api.nvim_create_augroup("HeirlineVimtex", { clear = true })
    local function set_vtex(state)
      return function()
        vimtex_state = state
        vim.cmd.redrawstatus()
      end
    end
    vim.api.nvim_create_autocmd("User", { group = vtex_group, pattern = "VimtexEventCompileStarted", callback = set_vtex "running" })
    vim.api.nvim_create_autocmd("User", { group = vtex_group, pattern = "VimtexEventCompileRunning", callback = set_vtex "running" })
    vim.api.nvim_create_autocmd("User", { group = vtex_group, pattern = "VimtexEventCompileSuccess", callback = set_vtex "success" })
    vim.api.nvim_create_autocmd("User", { group = vtex_group, pattern = "VimtexEventCompileFailed", callback = set_vtex "failed" })
    vim.api.nvim_create_autocmd("User", { group = vtex_group, pattern = "VimtexEventCompileStopped", callback = set_vtex(nil) })

    opts.statusline = { -- statusline
      hl = { fg = "fg", bg = "bg" },
      status.component.mode(),
      status.component.git_branch(),
      status.component.file_info(),
      status.component.git_diff(),
      status.component.diagnostics(),
      status.component.fill(),
      status.component.cmd_info(),
      status.component.fill(),
      status.component.lsp(),
      status.component.virtual_env(),
      status.component.treesitter(),
      status.component.nav(),
      status.component.builder {
        {
          provider = function() return os.date "%I:%M %p" end,
          update = { "ModeChanged", "BufEnter" },
        },
        padding = { left = 1, right = 1 },
      },
      status.component.mode { surround = { separator = "right" } },
      status.component.builder {
        condition = function()
          return vim.tbl_contains({ "tex", "markdown", "text" }, vim.bo.filetype)
        end,
        {
          provider = function()
            if vim.bo.filetype ~= "tex" then return prose.word_count() end
            local file = vim.api.nvim_buf_get_name(0)
            local tick = vim.b.changedtick
            if file ~= "" and not tc_running and (file ~= tc_cache.file or tick ~= tc_cache.tick) then
              tc_running = true
              tc_cache.tick = tick
              tc_cache.file = file
              vim.system(
                { "texcount", "-1", "-sum", "-merge", file },
                { text = true },
                function(out)
                  tc_running = false
                  if out.code == 0 then
                    local count = out.stdout:match "(%d+)"
                    if count then
                      tc_cache.result = count .. " words"
                      vim.schedule(function() vim.cmd.redrawstatus() end)
                    end
                  end
                end
              )
            end
            return tc_cache.result
          end,
          update = { "BufEnter", "BufWritePost" },
        },
      },
      status.component.builder {
        condition = function() return vim.bo.filetype == "tex" and vimtex_state ~= nil end,
        {
          provider = function()
            if vimtex_state == "running" then return "⟳ compiling"
            elseif vimtex_state == "success" then return "✓ ok"
            elseif vimtex_state == "failed" then return "✗ errors"
            end
            return ""
          end,
          hl = function()
            if vimtex_state == "running" then return { fg = "yellow" }
            elseif vimtex_state == "success" then return { fg = "green" }
            elseif vimtex_state == "failed" then return { fg = "red" }
            end
          end,
        },
        padding = { left = 1, right = 1 },
      },
    }

    opts.winbar = { -- winbar
      init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end,
      fallthrough = false,
      { -- inactive winbar
        condition = function() return not status.condition.is_active() end,
        status.component.separated_path(),
        status.component.file_info {
          file_icon = {
            hl = status.hl.file_icon "winbar",
            padding = { left = 0 },
          },
          filename = {},
          filetype = false,
          file_read_only = false,
          hl = status.hl.get_attributes("winbarnc", true),
          surround = false,
          update = "BufEnter",
        },
      },
      { -- active winbar
        status.component.breadcrumbs {
          hl = status.hl.get_attributes("winbar", true),
        },
      },
    }

    opts.tabline = { -- tabline
      { -- file tree padding
        condition = function(self)
          self.winid = vim.api.nvim_tabpage_list_wins(0)[1]
          self.winwidth = vim.api.nvim_win_get_width(self.winid)
          return self.winwidth ~= vim.o.columns -- only apply to sidebars
            and not require("astrocore.buffer").is_valid(vim.api.nvim_win_get_buf(self.winid)) -- if buffer is not in tabline
        end,
        provider = function(self) return (" "):rep(self.winwidth + 1) end,
        hl = { bg = "tabline_bg" },
      },
      status.heirline.make_buflist(status.component.tabline_file_info()), -- component for each buffer tab
      status.component.fill { hl = { bg = "tabline_bg" } }, -- fill the rest of the tabline with background color
      { -- tab list
        condition = function() return #vim.api.nvim_list_tabpages() >= 2 end, -- only show tabs if there are more than one
        status.heirline.make_tablist { -- component for each tab
          provider = status.provider.tabnr(),
          hl = function(self) return status.hl.get_attributes(status.heirline.tab_type(self, "tab"), true) end,
        },
        { -- close button for current tab
          provider = status.provider.close_button {
            kind = "TabClose",
            padding = { left = 1, right = 1 },
          },
          hl = status.hl.get_attributes("tab_close", true),
          on_click = {
            callback = function() require("astrocore.buffer").close_tab() end,
            name = "heirline_tabline_close_tab_callback",
          },
        },
      },
    }

    opts.statuscolumn = { -- statuscolumn
      init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end,
      status.component.foldcolumn(),
      status.component.numbercolumn(),
      status.component.signcolumn(),
    }
  end,
}
