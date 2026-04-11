return {
  "saghen/blink.cmp",
  optional = true,
  dependencies = {
    -- add the legacy cmp source as a dependency for `blink.cmp`
    "micangl/cmp-vimtex",
  },
  specs = {
    -- install the blink, nvim-cmp compatibility layer
    { "Saghen/blink.compat", version = "*", lazy = true, opts = {} },
  },
  opts = function(_, opts)
    opts.sources = opts.sources or {}
    opts.sources.default = opts.sources.default or {}
    vim.list_extend(opts.sources.default, { "latex" })
    opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
      latex = {
        name = "vimtex",
        module = "blink.compat.source",
        score_offset = -1,
      },
    })
    return opts
  end,
}
