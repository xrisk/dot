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
