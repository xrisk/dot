-- Claude Code integration for Neovim
-- Open Claude Code and send buffer/selection context

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      local maps = opts.mappings
      maps.n = maps.n or {}
      maps.v = maps.v or {}

      -- Open Claude Code in current project
      maps.n["<Leader>cc"] = {
        function()
          local cwd = vim.fn.getcwd()
          vim.fn.jobstart({ "claude", "--cwd", cwd }, {
            on_exit = function() end,
            detach = true,
          })
          vim.notify("Opening Claude Code...", vim.log.levels.INFO)
        end,
        desc = "Open Claude Code in project",
      }

      -- Send current buffer to Claude Code
      maps.n["<Leader>cs"] = {
        function()
          local file = vim.fn.expand("%:p")
          vim.fn.jobstart({ "claude", file }, {
            on_exit = function() end,
            detach = true,
          })
          vim.notify("Sent to Claude Code: " .. file, vim.log.levels.INFO)
        end,
        desc = "Send buffer to Claude Code",
      }

      -- Send selection to Claude Code
      maps.v["<Leader>cs"] = {
        function()
          local file = vim.fn.expand("%:p")
          local start_line = vim.fn.line("'<")
          local end_line = vim.fn.line("'>")
          local context = string.format("%s:%d-%d", file, start_line, end_line)
          vim.fn.jobstart({ "claude", context }, {
            on_exit = function() end,
            detach = true,
          })
          vim.notify("Sent selection to Claude Code", vim.log.levels.INFO)
        end,
        desc = "Send selection to Claude Code",
      }
    end,
  },
}
