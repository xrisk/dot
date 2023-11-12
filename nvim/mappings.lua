---@type MappingsTable
local M = {}

M.disabled = {
  n = {
    ["<tab>"] = "",
    ["<S-tab>"] = "",
    [";"] = "",
    ["<C-n>"] = "",
  },
}

M.general = {
  n = {
    ["<C-b>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle NvimTree" },
    ["<leader>xx"] = { "<cmd> TroubleToggle <CR>" },
  },
  v = {
    [">"] = { ">gv", "indent" },
  },
}

M.telescope = {
  n = {
    ["<C-p>"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    ["<C-t>"] = { "<cmd> Telescope lsp_document_symbols <CR>", "Find symbols in document" },
  },
}

M.tabufline = {
  n = {
    ["+"] = {
      function()
        require("nvchad.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },
    ["-"] = {
      function()
        require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },
  },
}

return M
