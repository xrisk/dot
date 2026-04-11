-- Official Claude Code Neovim integration
-- WebSocket server that Claude Code CLI connects to automatically

---@type LazySpec
return {
  {
    "coder/claudecode.nvim",
    opts = {},
  },
}
