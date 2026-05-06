---@type LazySpec
return {
  { "windwp/nvim-autopairs", enabled = false },
  {
    "folke/persistence.nvim",
    lazy = false,
    opts = {},
    config = function(_, opts)
      require("persistence").setup(opts)
      -- Close neo-tree before saving so its window isn't stored in the session
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function() pcall(vim.cmd, "Neotree close") end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if vim.fn.getcwd() == vim.fn.expand("~/thesis") and vim.fn.argc() == 0 then
            -- Defer so Lazy finishes loading plugins before restoring the session
            vim.defer_fn(function() require("persistence").load() end, 100)
          end
        end,
      })
    end,
  },
  { "folke/zen-mode.nvim" },
  { "junegunn/limelight.vim" },
  {
    "folke/snacks.nvim",
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = false },
    },
  },
  { "lunacookies/vim-colors-xcode" },
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      settings = {
        search = {
          uv = { command = "$FD '/bin/python$' $CWD/.venv --full-path --color never -H" },
          uv_python = { command = "$FD '/bin/python3$' ~/.local/share/uv/python --full-path --color never -H -I" },
        },
      },
    },
  },
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
    diff_opts = {
      layout = "vertical", -- "vertical" or "horizontal"
      open_in_new_tab = true,
      keep_terminal_focus = false, -- If true, moves focus back to terminal after diff opens
      hide_terminal_in_new_tab = false,
      -- on_new_file_reject = "keep_empty", -- "keep_empty" or "close_window"

      -- Legacy aliases (still supported):
      -- vertical_split = true,
      -- open_in_current_tab = true,
    },
  },
}
