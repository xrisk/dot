#!/bin/zsh
set -eu

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

CONTAINER_NAME="${HINDSIGHT_CONTAINER_NAME:-hindsight}"
IMAGE="${HINDSIGHT_IMAGE:-ghcr.io/vectorize-io/hindsight:latest}"
API_PORT="${HINDSIGHT_API_PORT:-8888}"
UI_PORT="${HINDSIGHT_UI_PORT:-9999}"
API_HOST="${HINDSIGHT_API_HOST_BIND:-127.0.0.1}"
UI_HOST="${HINDSIGHT_UI_HOST_BIND:-127.0.0.1}"
DATA_DIR="${HINDSIGHT_DATA_DIR:-/Users/xrisk/.hindsight-podman}"
CODEX_DIR="${HINDSIGHT_CODEX_DIR:-/Users/xrisk/.codex}"
MACHINE_NAME="${PODMAN_MACHINE_NAME:-podman-machine-default}"

if ! command -v podman >/dev/null; then
  echo "podman is not installed or not on PATH" >&2
  exit 127
fi

mkdir -p "$DATA_DIR"

if [[ "$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}')" != "running" ]]; then
  podman machine start "$MACHINE_NAME"
fi

# Give the forwarded Podman API socket a short window to come up after login.
for _ in {1..30}; do
  if podman info >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

current_fingerprint=""
if podman container exists "$CONTAINER_NAME"; then
  current_fingerprint="$(podman inspect "$CONTAINER_NAME" | python3 -c '
import json, sys
c = json.load(sys.stdin)[0]
parts = [c.get("ImageName", "")]
for container_port, bindings in sorted((c.get("NetworkSettings", {}).get("Ports") or {}).items()):
    for binding in bindings or []:
        parts.append("{}:{}->{}".format(binding.get("HostIp", ""), binding.get("HostPort", ""), container_port))
for mount in c.get("Mounts", []):
    suffix = "" if mount.get("RW") else ":ro"
    parts.append("{}:{}{}".format(mount.get("Source", ""), mount.get("Destination", ""), suffix))
print("|".join(parts))
' || true)"
fi

case "$current_fingerprint" in
  *"$IMAGE"*"${API_HOST}:${API_PORT}->8888/tcp"*"${UI_HOST}:${UI_PORT}->9999/tcp"*"${DATA_DIR}:/home/hindsight/.pg0"*"${CODEX_DIR}:/home/hindsight/.codex:ro"*)
    podman start "$CONTAINER_NAME"
    ;;
  *)
    if podman container exists "$CONTAINER_NAME"; then
      podman rm -f "$CONTAINER_NAME"
    fi
    podman run -d \
      --pull=always \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -p "${API_HOST}:${API_PORT}:8888" \
      -p "${UI_HOST}:${UI_PORT}:9999" \
      -e HINDSIGHT_API_WORKER_ID=hindsight-local \
      -e HINDSIGHT_API_LLM_PROVIDER=openai-codex \
      -e HINDSIGHT_API_LLM_MODEL=gpt-5.4-mini \
      -v "${DATA_DIR}:/home/hindsight/.pg0" \
      -v "${CODEX_DIR}:/home/hindsight/.codex:ro" \
      "$IMAGE"
    ;;
esac
