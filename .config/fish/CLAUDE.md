# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Fish Shell Configuration

This is the fish shell config, managed as part of the dotfiles repo at `~/dot/.config/fish/`. It targets fish + [fisher](https://github.com/jorgebucaran/fisher) on macOS (Apple Silicon, Homebrew at `/opt/homebrew`).

## Plugin Management

Plugins are managed by **fisher**. The authoritative list is `fish_plugins`:

```
jorgebucaran/fisher
pure-fish/pure       # prompt
jorgebucaran/nvm.fish
patrickf1/fzf.fish
```

To install/sync plugins: `fisher update`
To add a plugin: `fisher install <repo>` (this updates `fish_plugins` automatically)

## conf.d/ loading order

Files in `conf.d/` load alphabetically. Load-order dependencies:

1. `00-xdg.fish` — **must load first**; defines `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_STATE_HOME`, `$XDG_CACHE_HOME`. All other conf.d files reference these vars.
2. Everything else is independent of each other.

### What each conf.d file does

| File | Purpose |
|---|---|
| `00-xdg.fish` | XDG Base Directory variables |
| `aws.fish` | Moves AWS credentials/config under XDG |
| `devops.fish` | XDG overrides for Gradle, Ansible, Docker, kubectl |
| `history.fish` | Moves REPL histories (psql, mysql, node, python, sqlite, redis) under `$XDG_STATE_HOME` |
| `java.fish` | Java/JVM env setup |
| `misc.fish` | XDG overrides for wrangler, composer, conda, minikube |
| `node.fish` | `$NODE_GYP_DIR` under XDG cache |
| `python.fish` | IPython, matplotlib, Jupyter dirs under XDG |
| `rbenv.fish` | rbenv init |
| `ruby.fish` | Ruby gem paths |
| `rust.fish` | `$CARGO_HOME` and `$RUSTUP_HOME` under `$XDG_DATA_HOME`; adds cargo/bin to PATH |
| `pure.fish` | pure-fish/pure prompt defaults (colors, symbols, features) |
| `_pure_init.fish` | pure prompt initialization hook |
| `zellij.fish` | Zellij terminal multiplexer session init (large file — edit with offset/limit) |

## config.fish

The main config sets:
- Homebrew environment (prefix `/opt/homebrew`)
- `pure_show_system_time true`
- SSH auth socket pointing to **Secretive** (`com.maxgoedjen.Secretive.SecretAgent`)
- Git abbreviations (`gc`, `gs`, `ga`, `glog`, `gco`, `gp`, `gl`, `gd`) and `k` → `kubectl`
- `$EDITOR = nvim`
- Kanagawa color scheme for fish syntax highlighting
- `ffmpeg@7` pinned: PATH, `$DYLD_LIBRARY_PATH`, `$LDFLAGS`, `$CPPFLAGS`, `$PKG_CONFIG_PATH`
- `zoxide init fish | source` (replaces the old z.fish / `__z*` functions that were deleted)
- `$UV_TORCH_BACKEND auto`

## Secrets

API keys and tokens go in `~/.config/fish/conf.d/secrets.fish` (gitignored — never committed). `config.fish` sources it at startup if it exists:

```fish
# secrets.fish — example
set -gx HF_TOKEN hf_...
```

## Key design choices

- **zoxide** replaced the old hand-rolled `z`/`__z*` functions. The `z.fish` conf.d file and `__z*.fish` functions were deleted; `zoxide` is now initialized at the bottom of `config.fish`.
- Cursor shape is `block` in all modes (default, insert, replace, visual) — intentional vi-mode preference.
- `$fish_greeting` is cleared (no greeting on shell start).
- `$NVIM_APPNAME` is commented out — the default Neovim config location (`~/.config/nvim`) is used.
