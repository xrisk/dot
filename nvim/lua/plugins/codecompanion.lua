-- CodeCompanion.nvim - AI coding assistant integrated into Neovim
-- Chat interface, code explanations, refactoring, and more

---@type LazySpec
return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = "claude_3_5_sonnet",
          inline = "claude_3_5_sonnet",
        },
        adapters = {
          claude_3_5_sonnet = function()
            return require("codecompanion.adapters").extend("claude", {
              env = {
                api_key = "ANTHROPIC_API_KEY",
              },
              schema = {
                model = {
                  default = "claude-3-5-sonnet-20241022",
                },
              },
            })
          end,
        },
      })
    end,
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      local maps = opts.mappings
      maps.n = maps.n or {}
      maps.v = maps.v or {}

      -- CodeCompanion keybindings
      maps.n["<Leader>ac"] = { "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion chat" }
      maps.v["<Leader>ac"] = { "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion chat" }
      maps.n["<Leader>aa"] = { "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion actions" }
      maps.v["<Leader>aa"] = { "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion actions" }
    end,
  },
}
