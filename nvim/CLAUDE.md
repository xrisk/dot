# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Repository

This is an **AstroNvim v6** user configuration. AstroNvim is a Neovim IDE framework built on Lazy.nvim. This config layer sits on top of the framework; the framework itself is not in this repo.

## Configuration Loading Order

1. **`init.lua`** — Bootstrap only. Sets `<Leader>` / `<LocalLeader>` and loads Lazy.nvim. Do not modify.
2. **`lua/lazy_setup.lua`** — Lazy.nvim setup. Imports AstroNvim core, then `community.lua`, then `plugins/`.
3. **`lua/community.lua`** — AstroCommunity module imports (language packs, colorschemes). Processed before user plugins.
4. **`lua/plugins/`** — User plugin specs, loaded after community modules.
5. **`lua/polish.lua`** — Post-setup hook (currently disabled with guard line).

## Active Plugin Files

| File | Purpose |
|---|---|
| `lua/plugins/user.lua` | Custom plugins and overrides. Main file to edit for new plugins. |
| `lua/plugins/astrocore.lua` | Vim options, keymaps, treesitter, diagnostics. **Active** (guard removed). |
| `lua/plugins/treesitter.lua` | Treesitter ensure_installed and settings (extends astrocore opts). |

### Guard line pattern

Files with `if true then return {} end` at the top are disabled. Remove that line to activate.

## Active Customizations (astrocore.lua)

- **Diagnostics**: `virtual_text = false`, `virtual_lines = true` (shows errors as virtual lines, not inline text)
- **Numbers**: `relativenumber = false`, `number = true`
- **Line wrap**: `wrap = true`
- **Keymaps**: `0`→`g0`, `$`→`g$` (navigate wrapped lines); `\` disabled; `]b`/`[b` for buffer navigation
- **Colorscheme**: kanagawa

## Active Plugins (user.lua)

- **persistence.nvim** — session management; auto-restores session when opening `~/thesis` with no args; closes neo-tree before saving sessions
- **zen-mode.nvim** + **limelight.vim** — distraction-free writing
- **venv-selector.nvim** — Python venv picker; configured for `uv` and `uv python` backends using `$FD`
- **claudecode.nvim** — Claude Code integration (`<Leader>a*` keymaps); diffs open vertically in new tab
- **snacks.nvim** — bigfile enabled; dashboard disabled
- **vim-colors-xcode** — extra colorscheme
- **nvim-autopairs** — disabled

## Community Language Packs Enabled (community.lua)

lua, java, python, ruby, go, cpp, rust, lean, zig + vimtex (LaTeX) + neogit

## Formatting / Linting

- **StyLua** (`.stylua.toml`): Lua formatter. Run with `:!stylua %` or via LSP formatting.
- **Selene** (`selene.toml`): Lua linter.
- **`.luarc.json`**: Configures lua_ls for this repo's Neovim globals.

## Useful In-Neovim Commands

- `:Lazy` — plugin manager UI
- `:Lazy update` / `:Lazy sync` / `:Lazy restore` — manage plugins
- `:AstroLog` — AstroNvim internal logs
- `:checkhealth` — LSP, treesitter, plugin health
