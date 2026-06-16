-- Neo-tree overrides: open the file under the cursor in a macOS app.
--
-- Markdown files -> MacDown 3000; everything else (and directories) -> the
-- default app / Finder, via `open`.
--
-- Two entry points:
--   * keymap `O` in the tree ("Open externally")
--   * a "Open Externally" item in Neovim's built-in right-click PopUp menu
--     (works because mousemodel=popup_setpos: right-click moves the cursor to
--     the file, then the menu item opens it). The item is shown only while a
--     neo-tree window is focused, so the normal buffer right-click menu stays
--     untouched.

---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    local MARKDOWN_EXTS = { md = true, markdown = true, mdown = true, mkd = true, mkdn = true, markdn = true }

    -- Open a path in a macOS app: markdown -> MacDown 3000, else default app.
    local function open_path(path)
      if not path or path == "" then return end
      local ext = vim.fn.fnamemodify(path, ":e"):lower()
      local cmd = MARKDOWN_EXTS[ext] and { "open", "-a", "MacDown 3000", path } or { "open", path }
      vim.system(cmd, { text = true }, function(obj)
        if obj.code ~= 0 then
          vim.schedule(function()
            vim.notify(
              ("Failed to open %s\n%s"):format(vim.fn.fnamemodify(path, ":t"), obj.stderr or ""),
              vim.log.levels.ERROR,
              { title = "neo-tree" }
            )
          end)
        end
      end)
    end

    local function node_path(node)
      if not node or node.type == "message" then return nil end
      return node.path or node:get_id()
    end

    -- Keymap handler: state is passed in by neo-tree.
    opts.commands = opts.commands or {}
    opts.commands.open_external = function(state) open_path(node_path(state.tree:get_node())) end
    opts.window = opts.window or {}
    opts.window.mappings = opts.window.mappings or {}
    opts.window.mappings["O"] = "open_external"

    -- Right-click PopUp handler: resolve the node under the cursor from the
    -- focused neo-tree window's source state.
    vim.api.nvim_create_user_command("NeoTreeOpenExternal", function()
      local ok, manager = pcall(require, "neo-tree.sources.manager")
      if not ok then return end
      local state = manager.get_state(vim.b.neo_tree_source or "filesystem")
      if state and state.tree then open_path(node_path(state.tree:get_node())) end
    end, { desc = "Open the neo-tree node under the cursor in a macOS app" })

    local grp = vim.api.nvim_create_augroup("NeoTreeExternalMenu", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
      group = grp,
      callback = function()
        if vim.bo.filetype == "neo-tree" then
          vim.cmd [[silent! nnoremenu PopUp.Open\ Externally <Cmd>NeoTreeOpenExternal<CR>]]
        end
      end,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      group = grp,
      callback = function()
        if vim.bo.filetype == "neo-tree" then vim.cmd [[silent! nunmenu PopUp.Open\ Externally]] end
      end,
    })

    return opts
  end,
}
