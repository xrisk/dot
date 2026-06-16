# Hindsight host setup

Last verified: 2026-06-16 on `xrisk`'s Mac.

This directory documents the live Hindsight setup. The running configuration lives in the user home directory; this repo is the handoff note.

## Runtime

Hindsight runs locally in Podman.

- Container: `hindsight`
- Image: `ghcr.io/vectorize-io/hindsight:latest`
- API: `http://127.0.0.1:8888`
- UI: `http://127.0.0.1:9999`
- Persistent data: `/Users/xrisk/.hindsight-podman` mounted at `/home/hindsight/.pg0`
- Codex history mount: `/Users/xrisk/.codex` mounted read-only at `/home/hindsight/.codex`
- LLM provider: `openai-codex`
- LLM model: `gpt-5.4-mini`

Health check:

```sh
python3 - <<'PY'
from urllib.request import urlopen
print(urlopen('http://127.0.0.1:8888/health', timeout=5).read().decode())
PY
```

Expected response:

```json
{"status":"healthy","database":"connected"}
```

## Startup

LaunchAgent:

```text
/Users/xrisk/Library/LaunchAgents/io.rishav.hindsight.plist
```

Launcher:

```text
/Users/xrisk/.omp/scripts/start-hindsight-login.sh
```

The LaunchAgent runs at login and every 300 seconds. The launcher starts the Podman machine if needed, waits briefly for Podman readiness, then starts or recreates only the `hindsight` container.

Optimizations applied:

- API/UI bind to `127.0.0.1`, not `0.0.0.0`.
- Data persists outside the container in `/Users/xrisk/.hindsight-podman`.
- `/Users/xrisk/.codex` is mounted read-only.
- Container restart policy is `unless-stopped`.
- The launcher fingerprints image, ports, and mounts, avoiding unnecessary container churn.
- The LaunchAgent has `StartInterval = 300`, so a failed/stopped container is repaired after login.

Useful commands:

```sh
launchctl print gui/$(id -u)/io.rishav.hindsight
/Users/xrisk/.omp/scripts/start-hindsight-login.sh
podman ps --filter name=hindsight --format '{{.Names}} {{.Image}} {{.Status}} {{.Ports}}'
```

Podman VM note: `podman-machine-default` was running with 4 CPUs and 3814 MiB memory when checked. A prior container state showed OOM kill risk. Raising memory to 8192 MiB requires stopping the VM first, which interrupts other Podman containers:

```sh
podman machine stop podman-machine-default
podman machine set --memory 8192 podman-machine-default
podman machine start podman-machine-default
/Users/xrisk/.omp/scripts/start-hindsight-login.sh
```

## Codex integration

Hook scripts are installed in:

```text
/Users/xrisk/.hindsight/codex/scripts
```

Installed from Vectorize Hindsight's Codex integration. Hook events are configured in:

```text
/Users/xrisk/.codex/hooks.json
```

Hooks:

- `SessionStart`: `session_start.py`, timeout 5s. Checks Hindsight reachability.
- `UserPromptSubmit`: `recall.py`, timeout 12s. Injects relevant memories through Codex hook `additionalContext`.
- `Stop`: `retain.py`, timeout 30s. Retains the Codex transcript.

Codex feature flag in `/Users/xrisk/.codex/config.toml`:

```toml
[features]
memories = true
codex_hooks = true
```

Hindsight user config:

```text
/Users/xrisk/.hindsight/codex.json
```

Current choices:

```json
{
  "hindsightApiUrl": "http://127.0.0.1:8888",
  "apiPort": 8888,
  "bankIdPrefix": "local",
  "dynamicBankId": true,
  "dynamicBankGranularity": ["agent", "project"],
  "agentName": "codex",
  "autoRecall": true,
  "autoRetain": true,
  "retainMode": "full-session",
  "retainEveryNTurns": 1,
  "retainToolCalls": true,
  "recallBudget": "low",
  "recallMaxTokens": 800,
  "recallTimeout": 8,
  "recallContextTurns": 2,
  "recallMaxQueryChars": 1200
}
```

Bank IDs are project-scoped with the `local-` prefix, e.g. `local-codex::doc-annotator`.


## OMP `/collab` setup

OMP live sharing is configured in the user OMP config:

```text
/Users/xrisk/.omp/agent/config.yml
```

Relevant settings:

```yaml
collab:
  relayUrl: wss://omp.rishav.io
share:
  redactSecrets: true
extensions:
  - /Users/xrisk/.omp/agent/extensions/auto-collab
```

`/collab` in the OMP TUI uses the `wss://omp.rishav.io` relay when started manually. Share output redacts secrets by default.

The repo-owned auto-collab extension lives at:

```text
auto-collab-extension/index.ts
```

The installed extension path at `/Users/xrisk/.omp/agent/extensions/auto-collab/index.ts` re-exports that implementation. On `session_start`, it quietly starts a collab host, registers the session with `https://omp.rishav.io/api/sessions`, and keeps the dashboard record fresh until shutdown.

Maintenance note: the old PTY wrapper injection is intentionally disabled. `/Users/xrisk/.local/bin/omp` should only export `OMP_PID` and exec `omp.real`.

## Verification performed

Commands run successfully on 2026-06-16:

```sh
python3 -m compileall -q /Users/xrisk/.hindsight/codex/scripts
python3 -m json.tool /Users/xrisk/.hindsight/codex/settings.json
python3 -m json.tool /Users/xrisk/.hindsight/codex.json
python3 -m json.tool /Users/xrisk/.codex/hooks.json
zsh -n /Users/xrisk/.omp/scripts/start-hindsight-login.sh
/Users/xrisk/.omp/scripts/start-hindsight-login.sh
```

End-to-end hook smoke test:

1. Wrote a Codex JSONL transcript containing the fact `Smoke test project color is teal`.
2. Ran `session_start.py` against the transcript.
3. Ran `retain.py` against the transcript.
4. Ran `recall.py` with prompt `What color is the Hindsight smoke test project?`.
5. Recall returned `Smoke test project color is teal` in `hookSpecificOutput.additionalContext`.

This proves the local server is reachable, Codex hooks execute, retain writes to Hindsight, and recall injects memories in Codex's expected hook format.
