-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
---
---
---
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.ruby" },
  { import = "astrocommunity.colorscheme.solarized-osaka-nvim" },
  { import = "astrocommunity.markdown-and-latex.vimtex" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.cpp" },
  { import = "astrocommunity.colorscheme.nordic-nvim" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.lean" },
  { import = "astrocommunity.pack.zig" },
  -- { import = "astrocommunity.pack.haskell" },
  { import = "astrocommunity.git.neogit" },
  -- { import = "astrocommunity.ai.codecompanion-nvim" },
}
