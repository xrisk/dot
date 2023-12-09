local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "tsserver", "clangd", "pyright", "marksman", "leanls" }

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = function(client, bufnr)
			require("lsp-format").on_attach(client, bufnr)
			require("plugins.configs.lspconfig").on_attach(client, bufnr)
		end,
		capabilities = capabilities,
	})
end

--
-- lspconfig.pyright.setup { blabla}
