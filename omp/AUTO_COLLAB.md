# OMP auto-collab

Last verified: 2026-06-16 on `xrisk`'s Mac.

This documents the current auto-collab cutover so future agents do not reintroduce the old PTY `/collab` wrapper.

## Goal

Every interactive OMP session started through `omp` should appear on `https://omp.rishav.io` quietly. OMP startup may block briefly, but it must not print `/collab`, join links, browser links, or dashboard API output.

## Source of truth

- Repo implementation: `~/dot/omp/auto-collab-extension/index.ts`
- Installed extension shim: `~/.omp/agent/extensions/auto-collab/index.ts`
- OMP config path remains: `~/.omp/agent/config.yml`
- Wrapper: `~/.local/bin/omp`
- Real binary: `~/.local/bin/omp.real`
- Dashboard/relay server: `~/.omp/.tmp-omp-remote/server.ts`
- Dashboard token name: `omp-collab-dashboard-token` in the local `secret` store

The installed extension shim intentionally contains only:

```ts
export { default } from "/Users/xrisk/dot/omp/auto-collab-extension/index.ts";
```

Keep the implementation in the repo-owned subdirectory. Do not expand the installed shim back into a second implementation.

## Runtime behavior

`auto-collab-extension/index.ts` exports `autoCollab(pi)` and keeps the label `Auto Collab`.

On `session_start`, the extension:

1. Starts once per process.
2. Skips only when `ctx.hasUI === false`.
3. Generates an OMP-compatible collab room id, AES-256-GCM room key, and write token.
4. Opens `wss://omp.rishav.io/r/<roomId>?role=host`.
5. Registers a dashboard record at `https://omp.rishav.io/api/sessions` using `secret get omp-collab-dashboard-token` without printing the token.
6. Refreshes the dashboard record every 60 seconds.
7. Broadcasts lifecycle/tool/message events and state frames to connected guests.

On `session_shutdown`, the extension sends `bye`, closes the socket, deletes its dashboard record, and clears timers.

## Relay protocol notes

The extension implements the minimal OMP collab host protocol directly because the public extension API does not expose a safe built-in `/collab` executor, and `pi.sendUserMessage()` bypasses slash command parsing.

Frame invariants:

- Protocol version: `COLLAB_PROTO = 1`
- Room id: 16 random bytes, base64url-encoded
- Room key: 32 random bytes
- Write token: 16 random bytes
- Encryption: AES-GCM with fresh 12-byte IV per frame
- Binary envelope: 4-byte big-endian target peer id, then IV, then ciphertext
- Join link for production: `omp.rishav.io/r/<roomId>.<base64url(roomKey + writeToken)>`
- Dashboard web link: `https://omp.rishav.io/client/#<joinLink>`

Guest frames handled:

- `hello`: validates `proto === 1`, checks write token, replies with `welcome`
- `prompt`: write-capable guests call `pi.sendUserMessage(...)`; busy sessions use `{ deliverAs: "steer" }`
- `abort`: write-capable guests call `ctx.abort()`
- `agent-cmd`: rejected; agent control is not available from auto-collab
- `fetch-transcript`: rejected with an empty transcript response

Late joiners receive persisted safe entries from `ctx.sessionManager.getEntries()`. Live guests receive event/state frames; the extension does not synthesize an `entry` frame for every append.

## Wrapper invariant

`~/.local/bin/omp` must stay a quiet compatibility wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail

REAL="/Users/xrisk/.local/bin/omp.real"
if [[ ! -x "$REAL" ]]; then
	echo "omp wrapper: missing $REAL" >&2
	exit 127
fi

export OMP_PID="$$"
exec "$REAL" "$@"
```

Do not restore the old PTY parser or delayed `/collab` injection. That old behavior races the extension, can create duplicate hosts, and can leak startup output.

## Secret handling

Never print or store the dashboard token. If multiple checks need it, use:

```bash
secret prime omp-collab-dashboard-token
# run checks that invoke `secret get` inline
secret lock
```

The extension itself runs `secret get omp-collab-dashboard-token` with stdout piped and trims one trailing newline.

## Verification checklist

Run from `~/dot/omp` unless noted.

1. Static check:
   - Preferred when available: `bun --check auto-collab-extension/index.ts`
   - On this host during the cutover, `bun` was not in PATH; `tsc --noEmit --target ES2024 --module ESNext --moduleResolution Bundler --lib ES2024,DOM --strict` with a tiny local stub for `@oh-my-pi/pi-coding-agent` passed.
2. Wrapper:
   - `command -v omp` -> `/Users/xrisk/.local/bin/omp`
   - `/Users/xrisk/.local/bin/omp --version` -> `omp/16.0.2`
   - No collab or dashboard output.
3. Secret:
   - `secret ls` includes `omp-collab-dashboard-token`; do not run a bare `secret get`.
4. End-to-end startup:
   - Launch a fresh pty-backed interactive OMP session from `~/dot/omp`.
   - Wait until idle without typing.
   - `https://omp.rishav.io/api/sessions` should contain a fresh record with `cwd: "/Users/xrisk/dot/omp"`, `title: "omp"`, `joinLink` starting with `omp.rishav.io/r/`, and `webLink` starting with `https://omp.rishav.io/client/#`.
   - Captured terminal output should not contain `/collab`, `Collab session started`, join links, browser links, or dashboard output.
5. Relay protocol:
   - From a same-origin page such as `https://omp.rishav.io`, open the guest websocket for the room, send encrypted `hello`, and decrypt the `welcome` frame.
   - Expected: `welcome`, current `cwd`, persisted safe entries, and state participants.
6. Shutdown cleanup:
   - Exit the launched OMP session.
   - Re-read `https://omp.rishav.io/api/sessions`.
   - The fresh record id must be gone within a few seconds.

## Browser caveat

Headless Chrome navigating through `https://omp.rishav.io/client/#...` redirects to `https://my.omp.sh/#...`. That official client can fail with Chrome Private Network Access checks when it opens `wss://omp.rishav.io/...` from `my.omp.sh`. During cutover, same-origin protocol verification from `https://omp.rishav.io` succeeded even though the `my.omp.sh` redirect showed `reconnecting…` in headless Chrome.
