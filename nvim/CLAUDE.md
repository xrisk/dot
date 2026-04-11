# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Repository

This is an AstroNvim v6 user configuration. AstroNvim is a community-driven, extensible Neovim IDE framework built on Lazy.nvim. The repository provides a minimal template for customizing the framework with your personal plugins, keymaps, and LSP/language settings.

## Repository Structure

### Entry Points
- **init.lua** - Bootstrap file (do not modify). Sets up the Lua leader/localleader keys and loads Lazy.nvim
- **lua/lazy_setup.lua** - Lazy.nvim plugin manager configuration. Imports the AstroNvim core, community modules, and user plugins

### Configuration Layers (loaded in this order)
1. **lua/community.lua** - AstroCommunity module imports (language packs, colorschemes, etc.). Add community pack imports here
2. **lua/plugins/** - User plugin specs and configurations
   - **user.lua** - Add custom plugins and plugin overrides here
   - **astrocore.lua** - Vim options, keymaps, filetype definitions (currently disabled, remove guard line to activate)
   - **astrolsp.lua** - LSP client configuration, formatting, servers (currently disabled, remove guard line to activate)
   - **astroui.lua** - UI theme and statusline configuration (currently disabled)
   - **mason.lua** - LSP/DAP/formatter server installer configuration (currently disabled)
   - **none-ls.lua** - Linter/formatter integration via none-ls (currently disabled)
   - **treesitter.lua** - Syntax highlighting and text objects (currently disabled)
   - **kanagawa.lua** - Colorscheme configuration (currently disabled)
   - Other plugin-specific configs (heirline.lua, blink-vimtex.lua, etc.)
3. **lua/polish.lua** - Final post-setup hook for custom Lua code (currently disabled, remove guard line to activate)

### Configuration Files
- **.stylua.toml** - StyLua (Lua formatter) configuration
- **.luarc.json** - Lua Language Server configuration for editor support
- **.neoconf.json** - Neovim project-level configuration
- **selene.toml** - Selene (Lua linter) configuration

## Migrating from AstroNvim v5

Your v5 configuration is at `~/.config/nvim`. Key customizations to migrate to v6:

### From v5 astrocore.lua
Your custom settings that differ from v6 defaults:
- Diagnostics: `virtual_lines = true` (v6 has `virtual_text = true`) - update in **lua/plugins/astrocore.lua:18**
- Editor: `relativenumber = false` (v6 defaults to `true`) - update in **lua/plugins/astrocore.lua:43**
- Editor: `wrap = true` (v6 defaults to `false`) - update in **lua/plugins/astrocore.lua:47**
- Custom keymaps: `["0"] = { "g0" }` and `["$"] = { "g$" }` - add to **lua/plugins/astrocore.lua** mappings
- Keymap: `["\\"] = false` to disable backslash key - add to **lua/plugins/astrocore.lua** mappings

**Action:** Remove the guard line (`if true then return {} end`) in **lua/plugins/astrocore.lua** and apply these customizations.

### From v5 astrolsp.lua
- `inlay_hints = true` (v6 defaults to `false`) - update in **lua/plugins/astrolsp.lua:16**
- Custom yamlls configuration for Kubernetes schemas - add to **lua/plugins/astrolsp.lua:46** config section

**Action:** Remove the guard line in **lua/plugins/astrolsp.lua** and apply these settings.

### From v5 polish.lua
Your polish.lua has filetype definitions. These are already included in **lua/plugins/astrocore.lua** under the `filetypes` option, but the pattern syntax changed slightly in v6.

**Action:** Remove the guard line in **lua/polish.lua** if you need the custom filetype handling, or migrate the filetype definitions to **lua/plugins/astrocore.lua:28-39**.

### From v5 user.lua
Your v5 user.lua configuration is already identical in v6 - no changes needed.

## Working with Plugins

### Adding Plugins
Edit **lua/plugins/user.lua** to add custom plugins:
```lua
---@type LazySpec
return {
  {
    "github/repo",
    -- plugin configuration
  },
}
```

### Overriding AstroNvim Plugins
You can override any AstroNvim core plugin by adding its spec in **lua/plugins/user.lua**:
```lua
{
  "AstroNvim/astrocore",
  opts = { -- override options here }
}
```

### Community Modules
Add language packs and colorschemes by importing them in **lua/community.lua**:
```lua
{ import = "astrocommunity.pack.python" },
{ import = "astrocommunity.colorscheme.catppuccin" },
```

## Common Development Tasks

### Check Lua Syntax
The repository includes LSP configuration in `.luarc.json` for the Lua Language Server. Run `:LspInstall lua_ls` in Neovim to enable diagnostics while editing.

### Format Lua Code
StyLua is configured via `.stylua.toml`. Format a file with `:!stylua %` in Neovim.

### View Plugin Specs
Run `:Lazy` in Neovim to see the plugin manager UI, view installed plugins, and their status.

### Debug Configuration
- `:AstroLog` - View AstroNvim internal logs
- `:checkhealth` - Check Neovim health (LSP, treesitter, etc.)
- `:Telescope find_files` - Quickly navigate config files

## Key Differences from v5

- **LSP API changes**: `vim.lsp.buf.codelens.refresh()` changed to `vim.lsp.codelens.refresh()` in v6 (handled in astrolsp.lua:91)
- **Diagnostic method changes**: `client.supports_method()` changed to `client:supports_method()` in v6 (handled in astrolsp.lua:109)
- **Guard lines**: Many config files start with `if true then return {} end` to disable them - remove this line to activate
- **Plugin loading order**: Community imports before user plugins, ensuring community defaults are overridable

## Lazy.nvim Commands

Common commands to use inside Neovim:
- `:Lazy` - Open the Lazy plugin manager
- `:Lazy update` - Update all plugins
- `:Lazy sync` - Install missing plugins and remove extras
- `:Lazy restore` - Restore to lazy-lock.json versions
