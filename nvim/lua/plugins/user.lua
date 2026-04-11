---@type LazySpec
return {
  { "windwp/nvim-autopairs", enabled = false },
  { "folke/zen-mode.nvim" },
  { "junegunn/limelight.vim" },
  {
    "folke/snacks.nvim",
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = false },
      explorer = { enabled = true },
      picker = { enabled = true },
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
}
