---@type LazySpec
return {
  {
    "nickjvandyke/opencode.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    event = "VeryLazy",
    init = function()
      vim.g.opencode_opts = {
        server = {
          host = "127.0.0.1",
          port = 4096,
        },
        events = {
          reload = true,
        },
      }
    end,
    keys = {
      { "<C-,>", function() require("opencode").toggle() end, desc = "OpenCode: Ask" },
      { "<C-g>", function() require("opencode").ask() end, mode = "v", desc = "OpenCode: Ask" },
      { "<leader>os", function() require("opencode").select() end, desc = "OpenCode: Select Prompt" },
      { "<leader>ot", function() require("opencode").toggle() end, desc = "OpenCode: Toggle" },
      { "<leader>oy", function() require("opencode").accept() end, desc = "OpenCode: Accept Edit" },
      { "<leader>on", function() require("opencode").reject() end, desc = "OpenCode: Reject Edit" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    ---@module "render-markdown"
    ---@type render.md.UserConfig
    opts = {
      file_types = { "markdown" },
      completions = {
        lsp = {
          enabled = true,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        tex = { "tex-fmt" },
      },
      formatters = {
        ["tex-fmt"] = { prepend_args = { "--nowrap" } },
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
    event = "InsertEnter",
    dependencies = { "Saghen/blink.cmp" },
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
      provider = "openai_compatible",
      n_completions = 1,
      context_window = 1500,
      request_timeout = 15,
      notify = "warn",
      provider_options = {
        openai_compatible = {
          api_key = "OPENROUTER_API_KEY", -- pragma: allowlist secret
          name = "openrouter",
          end_point = "https://openrouter.ai/api/v1/chat/completions",
          model = "deepseek/deepseek-v4-flash",
          stream = false,
          few_shots = {
            {
              role = "user",
              content = [[
# language: tex
<contextBeforeCursor>
Social media platforms occupy a unique position as \emph{intermediaries}, giving them the power to <cursorPosition>
<contextAfterCursor>
and silence particular voices at scale.
]],
            },
            {
              role = "assistant",
              content = "shape public discourse",
            },
            {
              role = "user",
              content = [[
# language: tex
<contextBeforeCursor>
The decentralised architecture of the Fediverse distributes governance across multiple independent servers, each enforcing <cursorPosition>
<contextAfterCursor>
. This stands in contrast to centralised platforms, where a single entity sets policy for all users.
]],
            },
            {
              role = "assistant",
              content = "its own moderation policies",
            },
          },
          system = {
            template = "{{{prompt}}}\n{{{guidelines}}}\n{{{n_completion_template}}}",
            prompt = [[
You are a text completion engine for a formal academic LaTeX document.
Read the context around the cursor carefully and complete ONLY the phrase
at <cursorPosition>. The completion must be grammatically and logically
consistent with the sentence in progress.

Input markers:
- <contextBeforeCursor>: text before cursor
- <cursorPosition>: where you insert
- <contextAfterCursor>: text after cursor
]],
            guidelines = [[
Guidelines:
1. Output the completion text only — no labels, no numbering, no markdown.
2. One completion. No <endCompletion> marker.
3. A single short phrase of 3-4 words that continues the sentence naturally.
4. Do NOT copy or repeat text from <contextBeforeCursor>.
5. Honour LaTeX syntax in the surrounding text (\emph{}, \cite{}, \texttt{}, etc.).]],
            n_completion_template = "",
          },
          optional = {
            temperature = 0.2,
            provider = {
              sort = "throughput",
            },
            reasoning = {
              exclude = true,
            },
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
          score_offset = 5,
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
    "johnseth97/codex.nvim",
    enabled = false,
    cmd = { "Codex", "CodexToggle" },
    opts = {
      keymaps = {
        toggle = nil,
        quit = "<C-q>",
      },
      panel = true,
    },
    config = function(_, opts)
      require("codex").setup(opts)
    end,
    keys = {
      {
        "<C-g>",
        function() require("codex").toggle() end,
        mode = { "n", "t" },
        desc = "Codex: Toggle",
        silent = true,
      },
    },
  },

  {
    "stevearc/aerial.nvim",
    enabled = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        max_width = { 40, 0.2 },
        min_width = 20,
      },
      show_guides = true,
      filter_kind = false,
      attach_mode = "global",
      -- Auto-open for tex files so the outline is always visible when editing thesis
      open_automatic = function(bufnr) return vim.bo[bufnr].filetype == "tex" end,
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Toggle outline" },
    },
  },

  {
    "folke/edgy.nvim",
    enabled = false,
    event = "VeryLazy",
    init = function() vim.opt.splitkeep = "screen" end,
    opts = {
      left = {
        {
          title = "Files",
          ft = "neo-tree",
          filter = function(buf) return vim.b[buf].neo_tree_source == "filesystem" end,
          size = { height = 0.6 },
        },
        {
          title = "Outline",
          ft = "aerial",
          size = { height = 0.4 },
        },
      },
    },
  },
}
