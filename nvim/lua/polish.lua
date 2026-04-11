-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Disable treesitter highlighting for LaTeX (vimtex handles its own syntax)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "tex", "latex" },
  callback = function() vim.treesitter.stop() end,
})
