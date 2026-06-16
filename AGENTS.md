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
| `macdown/*.css` | `~/Library/Application Support/MacDown 3000/Styles/` (symlinked per file) |

## Tool-specific CLAUDE.md files

Each major tool has its own CLAUDE.md:

- **Fish shell**: `.config/fish/CLAUDE.md`
- **Neovim (AstroNvim v6)**: `nvim/CLAUDE.md`

> **Session hygiene**: When working in any subdirectory that has its own `CLAUDE.md` (`nvim/`, `.config/fish/`), update both the child `CLAUDE.md` and this file if the change is relevant to the broader repo. `~/.config/nvim` is a symlink to `~/dot/nvim` and `~/.config/fish` is a symlink to `~/dot/.config/fish` — edits made from either path land in the same repo.

## Conventions

- XDG Base Directory spec is enforced: all tool state goes under `~/.config`, `~/.local/share`, `~/.local/state`, or `~/.cache` — never directly in `$HOME`. New env-var overrides belong in `.config/fish/conf.d/`.
- The `conf.d/` files are loaded alphabetically; `00-xdg.fish` runs first to define `$XDG_*` variables that other files depend on.
- SSH auth is handled by [Secretive](https://github.com/maxgoedjen/secretive) via a custom `$SSH_AUTH_SOCK`.
- `ffmpeg@7` (pinned version) is on `$PATH` and its lib paths are set explicitly; do not change to `ffmpeg` (unpinned).
- **Secrets** (API keys, tokens) must never be committed inline. Put them in `~/.config/fish/conf.d/secrets.fish`, which is gitignored. `config.fish` sources it automatically if it exists.

## Secret Scanning

A pre-commit hook runs `detect-secrets` (via `uvx`) on every commit. On a fresh clone, activate it once:

```sh
git config core.hooksPath .githooks
```

If a false positive blocks a commit, regenerate the baseline:

```sh
uvx detect-secrets scan --all-files --exclude-files 'nvim/lazy-lock.json' > .secrets.baseline
git add .secrets.baseline
```
