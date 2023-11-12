local config = {}
for _, v in pairs(vim.fn.getcompletion("", "filetype")) do
  config[v] = { sync = true }
end
require("lsp-format").setup(config)
