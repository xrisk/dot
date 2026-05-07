---@type LazySpec
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        tex = { "tex-fmt" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "tex" then return { timeout_ms = 3000, lsp_fallback = false } end
      end,
    },
  },
  { "windwp/nvim-autopairs", enabled = false },
  {
    "folke/persistence.nvim",
    enabled = true,
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
          if vim.fn.getcwd() == vim.fn.expand "~/thesis" and vim.fn.argc() == 0 then
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
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "Saghen/blink.cmp",
    },
    opts = {
      virtualtext = {
        auto_trigger_ft = { "tex" },
        keymap = {
          accept = "<A-A>",
          accept_line = "<A-a>",
          accept_n_lines = "<A-z>",
          prev = "<A-[>",
          next = "<A-]>",
          dismiss = "<A-e>",
        },
      },
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 512,
      provider_options = {
        openai_fim_compatible = {
          api_key = "TERM",
          name = "Ollama",
          end_point = "http://localhost:11434/v1/completions",
          model = "qwen2.5-coder:3b",
          optional = {
            max_tokens = 5,
            temperature = 0.2,
            top_p = 0.5,
            stop = { "\n", "\t" },
          },
        },
      },
    },
  },

  {
    "Kaiser-Yang/blink-cmp-dictionary",
    dependencies = { "saghen/blink.cmp" },
  },

  {
    "niuiic/blink-cmp-rg.nvim",
    dependencies = { "saghen/blink.cmp" },
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        trigger = { prefetch_on_insert = false },
      })
      opts.fuzzy = vim.tbl_deep_extend("force", opts.fuzzy or {}, {
        frecency = { enabled = true },
        use_proximity = true,
      })
      opts.sources = opts.sources or {}
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        dictionary = {
          module = "blink-cmp-dictionary",
          name = "Dict",
          min_keyword_length = 3,
          score_offset = -3,
          opts = {
            dictionary_files = { "/usr/share/dict/words", vim.fn.expand "~/.local/share/nvim/dict/aspell-en.txt" },
          },
        },
        ripgrep = {
          module = "blink-cmp-rg",
          name = "Rg",
          score_offset = 2,
          opts = {
            prefix_min_len = 3,
            get_command = function(_, prefix)
              -- Add subdirectory names here to exclude them from word suggestions
              local exclude_dirs = { "mastodon-blog" }
              local cmd = {
                "rg",
                "--no-config",
                "--json",
                "--word-regexp",
                "--ignore-case",
              }
              for _, dir in ipairs(exclude_dirs) do
                table.insert(cmd, "--glob=!" .. dir)
              end
              vim.list_extend(cmd, {
                "--",
                prefix .. "[\\w_-]+",
                vim.fs.root(0, ".git") or vim.fn.getcwd(),
              })
              return cmd
            end,
          },
        },
      })
      return opts
    end,
  },

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
    opts = {
      diff_opts = {
        layout = "vertical",
        open_in_new_tab = true,
        keep_terminal_focus = true,
        hide_terminal_in_new_tab = false,
      },
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<C-l>", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<C-l>", "<cmd>ClaudeCode<cr>", mode = "t", desc = "Toggle Claude" },
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
  },
}
