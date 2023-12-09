-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
--

vim.g.mapleader = "\\"

local new_cmd = vim.api.nvim_create_user_command

new_cmd("Rg", function()
	require("telescope.builtin").live_grep()
end, {})

