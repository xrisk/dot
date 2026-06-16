# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Hygiene

At the end of every session where meaningful changes were made, update **both**:
- `nvim/CLAUDE.md` (this file) — Neovim-specific discoveries, plugin notes, gotchas
- `~/dot/CLAUDE.md` — repo-level notes if the change affects the broader dotfiles structure

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
| `lua/plugins/heirline.lua` | Statusline, winbar, tabline, statuscolumn overrides. |
| `lua/plugins/neo-tree.lua` | Neo-tree overrides; `O` keymap + right-click "Open Externally" PopUp item. |

### Guard line pattern

Files with `if true then return {} end` at the top are disabled. Remove that line to activate.

## Active Customizations (astrocore.lua)

- **Diagnostics**: `virtual_text = false`, `virtual_lines = true` (shows errors as virtual lines, not inline text)
- **Numbers**: `relativenumber = false`, `number = true`
- **Line wrap**: `wrap = true`
- **Keymaps**: `0`→`g0`, `$`→`g$` (navigate wrapped lines); `\` disabled; `]b`/`[b` for buffer navigation
- **Colorscheme**: kanagawa

## Neo-tree (neo-tree.lua)

Open the node under the cursor in a macOS app via `open`. Markdown (`md`/`markdown`/`mdown`/`mkd`/`mkdn`/`markdn`) → MacDown 3000 (`open -a "MacDown 3000"`, bundle `app.macdown.macdown3000`); everything else / directories → default app. Async via `vim.system`; notifies on failure. Two triggers:

- **`O` keymap** in the tree window (via `opts.commands.open_external` + `opts.window.mappings`). `O` is free by default (`o` is neo-tree's order-by prefix).
- **Right-click "Open Externally"** in Neovim's built-in `PopUp` menu. The neo-tree right-click menu is Neovim's own `PopUp` (default `mousemodel=popup_setpos`), **not** the terminal's — right-click moves the cursor to the file, then the item opens it. The `NeoTreeOpenExternal` user command resolves the node from `vim.b.neo_tree_source`'s state. The menu item is added on `BufEnter`/removed on `BufLeave` of neo-tree buffers (augroup `NeoTreeExternalMenu`) so the normal-buffer popup stays clean.

## Active Plugins (user.lua)

- **persistence.nvim** — session management; auto-restores session when opening `~/thesis` with no args. **Neo-tree + session gotcha**: `mksession` persists every listed buffer, so a neo-tree buffer (`neo-tree filesystem [N]`) gets written into the session; on restore neo-tree's `nvim_buf_set_name` collides → `E95: Buffer with this name already exists` (logged as `debounce filesystem_navigate error`), and the tree won't render. Just closing the window (`Neotree close`) is insufficient — it can fail on a modified buffer, leaving it listed. Fix: `wipe_neotree_buffers()` force-deletes any buffer with `filetype == "neo-tree"` or name `^neo-tree ` on **`PersistenceSavePre`** (clean saves) and **`PersistenceLoadPost`** (scrub already-poisoned sessions on load). To unblock a live session: wipe those buffers, then reopen neo-tree.
- **zen-mode.nvim** + **limelight.vim** — distraction-free writing
- **venv-selector.nvim** — Python venv picker; configured for `uv` and `uv python` backends using `$FD`
- **claudecode.nvim** (`coder/claudecode.nvim`) — Claude Code integration; runs a WebSocket server (same protocol as the official VS Code/JetBrains extensions) that the `claude` CLI auto-connects to. Depends on `snacks.nvim` (terminal); `diff_opts` uses a vertical layout opened in a new tab. Keymaps under `<leader>a` (AI/Claude Code): `<C-g>` toggle (n + t), `<C-l>` toggle (t), `ac` toggle, `af` focus, `ar` resume, `aC` continue, `am` select model, `ab` add buffer, `as` send selection (v) / add tree file (in file explorers), `aa` accept diff, `ad` deny diff. Config in `lua/plugins/coder-claude.lua`
- **codex.nvim** — OpenAI Codex integration (`<C-g>` toggle); opens as a side panel. **Disabled** (`enabled = false`) in favour of claudecode.nvim
- **render-markdown.nvim** — active on `markdown` buffers; renders headings/lists/links/code blocks in-editor and enables markdown checkbox/callout completions through the plugin's in-process LSP hook
- **snacks.nvim** — bigfile enabled; dashboard disabled
- **vim-colors-xcode** — extra colorscheme
- **nvim-autopairs** — disabled
- **minuet-ai.nvim** — ghost-text AI completions via OpenRouter free tier; `openai_compatible` provider, model `qwen/qwen3-8b:free`, auto-triggers on `tex` files only; `OPENROUTER_API_KEY` env var required; `context_window = 4000`, `max_tokens = 10` (3-4 word phrases); `notify = "debug"` — check `:messages` for latency
- **blink-cmp-dictionary** — English dictionary source for blink.cmp; reads `/usr/share/dict/words` + `~/.local/share/nvim/dict/aspell-en.txt` (aspell dump, ~105k words); active in `tex` files only. Regenerate aspell dump: `aspell -l en dump master | grep -v '^[[:upper:]]' | sort -u > ~/.local/share/nvim/dict/aspell-en.txt`
- **conform.nvim** — `latexindent` formatter for `tex` files on save (timeout 3s, no LSP fallback)
- **blink-cmp-rg.nvim** (`niuiic/blink-cmp-rg.nvim`) — ripgrep word source; searches git root with configurable subdirectory exclusions; `exclude_dirs` list in provider opts in `user.lua`
- **aerial.nvim** — document outline sidebar; auto-opens for `tex` files (shows section/subsection hierarchy via vimtex LSP); `<leader>o` to toggle manually; `filter_kind = false` (texlab only emits structural symbols anyway)
- **edgy.nvim** — sidebar layout manager; stacks neo-tree (top 60%) and aerial outline (bottom 40%) in the left column; requires `vim.opt.splitkeep = "screen"` in init

## Statusline (heirline.lua)

- **Clock**: shows current time as `HH:MM AM/PM`; updates on mode change / buf enter; a `vim.uv` timer in `astrocore.lua` (`clock_refresh` autocmd) fires `redrawstatus` every 60 s (aligned to the minute boundary) to keep it accurate while idle.
- **Word count**: shown for `tex`, `markdown`, `text` filetypes. For `tex`, uses `texcount -1 -sum -merge <file>` (reads from disk, so updates on `BufWritePost` / `BufEnter`); async via `vim.system` with a tick-based cache to avoid re-running on the `redrawstatus` triggered by its own completion. For other filetypes, falls back to `nvim-prose` (`vim.fn.wordcount()`). `texcount` ships with MacTeX/TeX Live — no separate install needed.

## Thesis Writing Setup (blink-vimtex.lua + user.lua + astrocore.lua)

The config is tuned for prose-only LaTeX thesis writing in `~/thesis`:

- **blink-vimtex.lua**: vimtex source `score_offset = 15` (beats snippets/buffer); `per_filetype.tex` source order = `{ latex, lsp, path, ripgrep, buffer, dictionary }` — snippets excluded
- **astrocore.lua**: FileType autocmd for `tex` enables `spell`, `linebreak`, `breakindent`, `showbreak`
- **`niuiic/blink-cmp-rg.nvim`**: Note — this plugin's `get_command` takes `(context, prefix)` and returns a plain string table; `mikavilpas/blink-ripgrep.nvim` was NOT used because its `get_command` returns an internal `RipgrepCommand` object that can't be constructed externally

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
