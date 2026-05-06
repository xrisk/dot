# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repo for macOS (Apple Silicon). It is **not** a software project — there are no build steps, tests, or CI. All files are meant to be symlinked (or copied) to their expected locations on the system.

Config locations managed here:

| Directory / File | Deployed to |
|---|---|
| `.config/fish/` | `~/.config/fish/` |
| `.config/karabiner/` | `~/.config/karabiner/` |
| `nvim/` | `~/.config/nvim/` (set via `$NVIM_APPNAME` or default) |
| `tmux.conf` | `~/.tmux.conf` |
| `Brewfile` | Used with `brew bundle` |
| `*.terminfo` | Compiled with `tic` and installed via `tic -x <file>` |

## Tool-specific CLAUDE.md files

Each major tool has its own CLAUDE.md:

- **Fish shell**: `.config/fish/CLAUDE.md`
- **Neovim (AstroNvim v6)**: `nvim/CLAUDE.md`

## Conventions

- XDG Base Directory spec is enforced: all tool state goes under `~/.config`, `~/.local/share`, `~/.local/state`, or `~/.cache` — never directly in `$HOME`. New env-var overrides belong in `.config/fish/conf.d/`.
- The `conf.d/` files are loaded alphabetically; `00-xdg.fish` runs first to define `$XDG_*` variables that other files depend on.
- SSH auth is handled by [Secretive](https://github.com/maxgoedjen/secretive) via a custom `$SSH_AUTH_SOCK`.
- `ffmpeg@7` (pinned version) is on `$PATH` and its lib paths are set explicitly; do not change to `ffmpeg` (unpinned).
- `$HF_TOKEN` is set in `config.fish` — do not commit changes that expose it or add other secrets inline.
