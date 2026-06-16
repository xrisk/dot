---
name: hindsight-codex-host-setup
description: "Use when maintaining this Mac's local Hindsight Podman runtime and Codex hook integration."
---

# Local Hindsight + Codex maintenance

Use this when asked to inspect, repair, optimize, or document Hindsight on xrisk's Mac.

## Source of truth

- Documentation: `~/dev/rishavs-omp/README.md`
- LaunchAgent: `~/Library/LaunchAgents/io.rishav.hindsight.plist`
- Launcher: `~/.omp/scripts/start-hindsight-login.sh`
- Codex hooks: `~/.codex/hooks.json`
- Hindsight Codex hook scripts: `~/.hindsight/codex/scripts`
- Hindsight Codex config: `~/.hindsight/codex.json`

## Runtime invariants

- Podman container: `hindsight`
- Image: `ghcr.io/vectorize-io/hindsight:latest`
- API: `http://127.0.0.1:8888`
- UI: `http://127.0.0.1:9999`
- Persistent data: `/Users/xrisk/.hindsight-podman` mounted at `/home/hindsight/.pg0`
- Codex history: `/Users/xrisk/.codex` mounted read-only at `/home/hindsight/.codex`
- API/UI must bind to `127.0.0.1`, not `0.0.0.0`

## Checks

Use `read` for static files and URL health checks. Use bash only for commands.

1. Health:
   - `read` URL `http://127.0.0.1:8888/health`
   - Expected JSON: `{"status":"healthy","database":"connected"}`
2. Validate hook scripts/config:
   - `python3 -m compileall -q /Users/xrisk/.hindsight/codex/scripts`
   - `python3 -m json.tool /Users/xrisk/.hindsight/codex.json`
   - `python3 -m json.tool /Users/xrisk/.codex/hooks.json`
   - `zsh -n /Users/xrisk/.omp/scripts/start-hindsight-login.sh`
3. Runtime visibility:
   - `podman ps --filter name=hindsight --format '{{.Names}} {{.Image}} {{.Status}} {{.Ports}}'`
   - `launchctl print gui/$(id -u)/io.rishav.hindsight`

## Codex integration expectations

`~/.codex/config.toml` should contain:

```toml
[features]
codex_hooks = true
```

`~/.codex/hooks.json` should configure:

- `SessionStart` -> `python3 "~/.hindsight/codex/scripts/session_start.py"`
- `UserPromptSubmit` -> `python3 "~/.hindsight/codex/scripts/recall.py"`
- `Stop` -> `python3 "~/.hindsight/codex/scripts/retain.py"`

`~/.hindsight/codex.json` should point to local API `http://127.0.0.1:8888`, use dynamic bank IDs by `agent + project`, and retain every turn.

## End-to-end hook smoke test

Create a tiny Codex JSONL transcript under `~/.hindsight/codex/`, run `session_start.py`, then `retain.py`, then `recall.py` with a prompt about the fact. Confirm `recall.py` outputs `hookSpecificOutput.additionalContext` containing the retained fact.

Do not put secret API keys in docs, prompts, or checked-in files. If a secret is needed, use the local `secret` store flow from the global instructions.
