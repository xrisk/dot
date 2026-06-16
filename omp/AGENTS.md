# Repository Guidelines

## Project Overview

This repository is a local OMP coding-harness support repo, not an application. It tracks optional tool manifests, runtime launch scripts, managed skills, and a tiny installed extension shim used by this Mac and by OMP container setups.

Keep the split clear: checked-in files describe or launch tooling; runtime state and generated dependency trees are ignored.

## Architecture & Data Flow

- `Brewfile.omp` is the macOS tool bootstrap: `brew bundle --file Brewfile.omp` installs LSPs, DAPs, shell tools, and format/check tools.
- `omp-optional-deps.sh` is the Ubuntu 24.04 bootstrap. It installs base packages, Node 22, uv, Deno, Go-installed tools, release binaries, isolated Python/Node tool projects under `/opt/omp-tools`, symlinks binaries into `/usr/local/bin`, then sets OMP browser/LSP/debug config when `omp` exists.
- `omp-python/` is a uv-managed Python tooling project. It is not packaged; it supplies `basedpyright`, `debugpy`, `python-lsp-server[all]`, and `ruff` for the harness.
- `omp-node-tools/` is a private npm language-server bundle. It has no package scripts; the lockfile is the source of truth for resolved Node tools.
- `scripts/start-hindsight-login.sh` starts the local Hindsight Podman runtime. It starts the Podman machine if needed, waits for readiness, fingerprints the existing container by image/ports/mounts, and recreates only when those inputs differ.
- `agent/extensions/auto-collab/index.ts` is intentionally only an absolute re-export to the real implementation in `/Users/xrisk/dot/omp/auto-collab-extension/index.ts`. Do not add logic to the shim.
- Auto-collab runtime flow is documented in `auto-collab-extension/AGENTS.md`: OMP session start opens a quiet host websocket, registers a dashboard record at `https://omp.rishav.io/api/sessions`, refreshes it, relays encrypted guest frames, accepts dashboard launch requests for new local chats, and deletes the record on shutdown.

## Key Directories

- `agent/extensions/` — source-controlled OMP extension shims only.
- `agent/managed-skills/` — source-controlled managed skills. Edit only managed skills; do not modify user-authored skills outside this tree.
- `omp-python/` — uv-managed Python tooling environment; read `omp-python/AGENTS.md` before edits there.
- `omp-node-tools/` — private npm project for Node-based language servers.
- `scripts/` — host launch scripts, currently the Hindsight login launcher.
- `logs/`, `session-worktrees/`, `.tmp-omp-remote/`, `natives/`, `venvs/`, most of `agent/` — generated runtime state; do not treat as source.

## Development Commands

There is no root build, test, or CI pipeline.

- macOS tool sync: `brew bundle --file Brewfile.omp`
- Python tools: `cd omp-python && uv sync`
- Node tools: `npm install --prefix omp-node-tools`
- Ubuntu/container bootstrap: `bash omp-optional-deps.sh`
- Hindsight launcher syntax check: `zsh -n scripts/start-hindsight-login.sh`
- Hindsight runtime health: read `http://127.0.0.1:8888/health`
- Hindsight support checks from the managed skill:
  - `python3 -m compileall -q /Users/xrisk/.hindsight/codex/scripts`
  - `python3 -m json.tool /Users/xrisk/.hindsight/codex.json`
  - `python3 -m json.tool /Users/xrisk/.codex/hooks.json`
  - `podman ps --filter name=hindsight --format '{{.Names}} {{.Image}} {{.Status}} {{.Ports}}'`
  - `launchctl print gui/$(id -u)/io.rishav.hindsight`

## Code Conventions & Common Patterns

- Shell scripts use strict mode (`set -euo pipefail` for bash, `set -eu` for zsh), small helper functions, and environment-variable defaults like `${NAME:-default}`.
- Prefer isolated tool installs over global package mutation: uv-managed Python projects, npm project prefixes, Homebrew bundles, and symlinked binaries.
- Do not use `pip --break-system-packages` or global npm installs for this repo’s tooling.
- Preserve source/state boundaries from `.gitignore`: commit manifests, lockfiles, shims, scripts, and managed skills; leave DBs, logs, sessions, venvs, node_modules, and temp relay files untracked.
- For secrets, use the local `secret` store inline. Never print tokens. For repeated auto-collab checks, bracket with `secret prime omp-collab-dashboard-token` and `secret lock`.
- Auto-collab must stay quiet: do not reintroduce PTY `/collab` injection, join-link stdout, dashboard output, or duplicate host startup.
- The Hindsight launcher should remain idempotent: fingerprint image, port bindings, and mounts before recreating the container.
- Prefer warnings/soft failure for optional tool installs so later installers still run; keep hard failures for violated shell invariants.

## Important Files

- `AGENTS.md` — repository guidance for AI assistants.
- `auto-collab-extension/AGENTS.md` — source-of-truth runbook for OMP auto-collab behavior, secrets, and verification.
- `Brewfile.omp` — Homebrew optional dependency manifest.
- `omp-optional-deps.sh` — Ubuntu 24.04 optional dependency/bootstrap script.
- `scripts/start-hindsight-login.sh` — local Hindsight Podman launcher.
- `agent/extensions/auto-collab/index.ts` — one-line installed shim; keep it one line.
- `agent/managed-skills/hindsight-codex-host-setup/SKILL.md` — Hindsight/Codex maintenance procedure and QA checklist.
- `omp-python/pyproject.toml`, `omp-python/uv.lock`, `omp-python/.python-version` — Python tool environment definition.
- `omp-node-tools/package.json`, `omp-node-tools/package-lock.json` — Node language-server environment definition.
- `.gitignore` — authoritative source/runtime boundary.

## Runtime/Tooling Preferences

- Primary host is macOS Apple Silicon; `Brewfile.omp` is the preferred host bootstrap.
- Linux/container setup targets Ubuntu 24.04 via `omp-optional-deps.sh`.
- Python tooling targets Python `>=3.14,<3.15` and is managed with uv.
- Node tooling is isolated in npm projects; Ubuntu bootstrap defaults to Node 22.
- Browser automation should be enabled and headless when `omp-optional-deps.sh` configures OMP.
- LSP and debug tooling are installed as optional external tools, then auto-detected/configured by OMP.
- Hindsight runs as Podman container `hindsight` on `127.0.0.1:8888` and `127.0.0.1:9999`, with persistent data in `/Users/xrisk/.hindsight-podman` and read-only Codex history from `/Users/xrisk/.codex`.

## Testing & QA

No test framework or coverage threshold is defined in this repo.

Use targeted checks based on touched files:

- Shell changes: `zsh -n scripts/start-hindsight-login.sh` or `bash -n omp-optional-deps.sh`.
- Python tooling changes: `cd omp-python && uv sync`; smoke with `python debug_smoke.py` if relevant.
- Node tooling changes: `npm install --prefix omp-node-tools` and inspect lockfile changes.
- Auto-collab changes: follow `auto-collab-extension/AGENTS.md`; prefer `bun --check auto-collab-extension/index.ts` when available, otherwise the documented `tsc --noEmit --target ES2024 --module ESNext --moduleResolution Bundler --lib ES2024,DOM --strict` check in the real implementation repo.
- Hindsight/Codex maintenance: use the compileall/json/zsh/podman/launchctl checks listed in `agent/managed-skills/hindsight-codex-host-setup/SKILL.md`.
