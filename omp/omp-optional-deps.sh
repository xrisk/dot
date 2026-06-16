#!/usr/bin/env bash
set -euo pipefail

# Optional OMP coding-harness dependencies for Ubuntu 24.04 containers.
# Installs tools referenced by the current OMP config, except memory/collab services.
# Python tools are managed by a dedicated uv project/venv. Node tools are managed
# by a dedicated npm project. No pip --break-system-packages and no global npm installs.

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

OMP_PREFIX="${OMP_PREFIX:-/opt/omp-tools}"
OMP_PYTHON_PROJECT="${OMP_PYTHON_PROJECT:-${OMP_PREFIX}/python}"
OMP_NODE_PROJECT="${OMP_NODE_PROJECT:-${OMP_PREFIX}/node}"
LOCAL_BIN="${LOCAL_BIN:-/usr/local/bin}"
NODE_MAJOR="${NODE_MAJOR:-22}"
PYTHON_VERSION="${PYTHON_VERSION:-3.14}"

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    warn "Need root for: $*"
    return 1
  fi
}

install_file() {
  local src="$1" dst="$2"
  as_root install -Dm755 "$src" "$dst"
}

symlink_bin() {
  local src="$1" name="${2:-}"
  [ -n "$name" ] || name="$(basename "$src")"
  if [ -e "$src" ]; then
    as_root mkdir -p "$LOCAL_BIN"
    as_root ln -sf "$src" "$LOCAL_BIN/$name"
  else
    warn "Missing binary for symlink: $src"
  fi
}

require_ubuntu_2404() {
  if [ ! -r /etc/os-release ]; then
    warn "Cannot confirm OS; this script assumes ubuntu:24.04."
    return 0
  fi

  # shellcheck source=/dev/null
  . /etc/os-release
  if [ "${ID:-}" != "ubuntu" ] || [ "${VERSION_ID:-}" != "24.04" ]; then
    warn "Detected ${PRETTY_NAME:-unknown}; this script is targeted at ubuntu:24.04."
  fi
}

install_apt_base() {
  log "Installing Ubuntu packages"
  as_root apt-get update
  as_root apt-get install -y --no-install-recommends \
    apt-transport-https \
    bash \
    ca-certificates \
    clang \
    clangd \
    curl \
    file \
    g++ \
    gcc \
    gdb \
    git \
    gnupg \
    golang-go \
    gzip \
    jq \
    less \
    libasound2t64 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    lldb \
    make \
    pkg-config \
    procps \
    python3 \
    python3-venv \
    shellcheck \
    shfmt \
    sudo \
    tar \
    unzip \
    xdg-utils \
    xz-utils
}

install_node() {
  if have node && node -e "process.exit(Number(process.versions.node.split('.')[0]) >= 20 ? 0 : 1)"; then
    return 0
  fi

  log "Installing Node.js ${NODE_MAJOR}.x from NodeSource"
  local setup
  setup="$(mktemp)"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" -o "$setup"
  as_root bash "$setup"
  rm -f "$setup"
  as_root apt-get install -y --no-install-recommends nodejs
}

install_uv() {
  if have uv; then
    return 0
  fi

  log "Installing uv"
  local installer tmpbin
  installer="$(mktemp)"
  curl -fsSL https://astral.sh/uv/install.sh -o "$installer"
  if [ "$(id -u)" -eq 0 ]; then
    UV_INSTALL_DIR="$LOCAL_BIN" sh "$installer"
  else
    sh "$installer"
    tmpbin="$HOME/.local/bin/uv"
    [ -x "$tmpbin" ] && as_root ln -sf "$tmpbin" "$LOCAL_BIN/uv"
  fi
  rm -f "$installer"
}

install_deno() {
  if have deno; then
    return 0
  fi

  log "Installing Deno"
  local tmpdir zip arch
  case "$(uname -m)" in
    x86_64|amd64) arch="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) arch="aarch64-unknown-linux-gnu" ;;
    *) warn "Unsupported Deno arch: $(uname -m)"; return 0 ;;
  esac
  tmpdir="$(mktemp -d)"
  zip="$tmpdir/deno.zip"
  curl -fsSL "https://github.com/denoland/deno/releases/latest/download/deno-${arch}.zip" -o "$zip"
  unzip -q "$zip" -d "$tmpdir"
  install_file "$tmpdir/deno" "$LOCAL_BIN/deno"
  rm -rf "$tmpdir"
}

write_python_project() {
  log "Writing uv-managed OMP Python project"
  as_root mkdir -p "$OMP_PYTHON_PROJECT"
  as_root tee "$OMP_PYTHON_PROJECT/.python-version" >/dev/null <<EOF_PYVER
${PYTHON_VERSION}
EOF_PYVER
  as_root tee "$OMP_PYTHON_PROJECT/pyproject.toml" >/dev/null <<'EOF_PYPROJECT'
[project]
name = "omp-python-tools"
version = "0.1.0"
description = "Python tools used by OMP in harness containers"
requires-python = ">=3.14,<3.15"
dependencies = [
  "basedpyright",
  "debugpy",
  "pyright",
  "python-lsp-server[all]",
  "ruff",
]

[tool.uv]
package = false
EOF_PYPROJECT
}

install_python_tools() {
  write_python_project
  log "Syncing Python tools with uv"
  as_root env HOME="$HOME" uv python install "$PYTHON_VERSION"
  as_root env HOME="$HOME" uv sync --project "$OMP_PYTHON_PROJECT" --python "$PYTHON_VERSION"

  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/pyright" pyright
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/pyright-langserver" pyright-langserver
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/basedpyright" basedpyright
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/basedpyright-langserver" basedpyright-langserver
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/pylsp" pylsp
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/ruff" ruff
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/debugpy" debugpy
  symlink_bin "$OMP_PYTHON_PROJECT/.venv/bin/debugpy-adapter" debugpy-adapter
}

write_node_project() {
  log "Writing isolated Node language-server project"
  as_root mkdir -p "$OMP_NODE_PROJECT"
  as_root tee "$OMP_NODE_PROJECT/package.json" >/dev/null <<'EOF_PACKAGE'
{
  "name": "omp-node-tools",
  "private": true,
  "description": "Node-based language servers used by OMP in harness containers",
  "dependencies": {
    "@astrojs/language-server": "latest",
    "@ast-grep/cli": "latest",
    "@olrtg/emmet-language-server": "latest",
    "@prisma/language-server": "latest",
    "@tailwindcss/language-server": "latest",
    "@vue/language-server": "latest",
    "bash-language-server": "latest",
    "dockerfile-language-server-nodejs": "latest",
    "graphql-language-service-cli": "latest",
    "svelte-language-server": "latest",
    "tree-sitter-cli": "latest",
    "typescript": "latest",
    "typescript-language-server": "latest",
    "vim-language-server": "latest",
    "vscode-langservers-extracted": "latest",
    "yaml-language-server": "latest"
  }
}
EOF_PACKAGE
}

install_node_tools() {
  write_node_project
  log "Installing isolated Node language servers"
  as_root npm install --prefix "$OMP_NODE_PROJECT"

  for bin in \
    astro-ls \
    ast-grep \
    bash-language-server \
    docker-langserver \
    emmet-language-server \
    graphql-lsp \
    prisma-language-server \
    svelteserver \
    tailwindcss-language-server \
    tree-sitter \
    tsserver \
    tsc \
    typescript-language-server \
    vim-language-server \
    vscode-css-language-server \
    vscode-eslint-language-server \
    vscode-html-language-server \
    vscode-json-language-server \
    vue-language-server \
    yaml-language-server; do
    symlink_bin "$OMP_NODE_PROJECT/node_modules/.bin/$bin" "$bin"
  done
}

latest_asset_url() {
  local repo="$1" regex="$2"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r --arg re "$regex" '.assets[] | select(.name | test($re)) | .browser_download_url' \
    | sed -n '1p'
}

install_marksman() {
  if have marksman; then
    return 0
  fi

  log "Installing Marksman Markdown LSP"
  local asset tmp
  case "$(uname -m)" in
    x86_64|amd64) asset="marksman-linux-x64" ;;
    aarch64|arm64) asset="marksman-linux-arm64" ;;
    *) warn "Unsupported Marksman arch: $(uname -m)"; return 0 ;;
  esac
  tmp="$(mktemp)"
  curl -fsSL "https://github.com/artempyanykh/marksman/releases/latest/download/${asset}" -o "$tmp"
  chmod +x "$tmp"
  install_file "$tmp" "$LOCAL_BIN/marksman"
  rm -f "$tmp"
}

install_texlab() {
  if have texlab; then
    return 0
  fi

  log "Installing texlab LaTeX LSP"
  local regex url tmpdir archive bin
  case "$(uname -m)" in
    x86_64|amd64) regex='(x86_64|x64).*linux.*(tar\.gz|tar\.xz)$' ;;
    aarch64|arm64) regex='(aarch64|arm64).*linux.*(tar\.gz|tar\.xz)$' ;;
    *) warn "Unsupported texlab arch: $(uname -m)"; return 0 ;;
  esac
  url="$(latest_asset_url latex-lsp/texlab "$regex")"
  if [ -z "$url" ]; then
    warn "Could not find texlab release asset."
    return 0
  fi
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/texlab.archive"
  curl -fsSL "$url" -o "$archive"
  tar -xf "$archive" -C "$tmpdir"
  bin="$(find "$tmpdir" -type f -name texlab -perm -111 | sed -n '1p')"
  if [ -n "$bin" ]; then
    install_file "$bin" "$LOCAL_BIN/texlab"
  else
    warn "texlab binary not found in archive."
  fi
  rm -rf "$tmpdir"
}

install_lua_language_server() {
  if have lua-language-server; then
    return 0
  fi

  log "Installing Lua language server"
  local regex url tmpdir archive srcdir
  case "$(uname -m)" in
    x86_64|amd64) regex='lua-language-server-.*linux-x64.*\.tar\.gz$' ;;
    aarch64|arm64) regex='lua-language-server-.*linux-arm64.*\.tar\.gz$' ;;
    *) warn "Unsupported LuaLS arch: $(uname -m)"; return 0 ;;
  esac
  url="$(latest_asset_url LuaLS/lua-language-server "$regex")"
  if [ -z "$url" ]; then
    warn "Could not find lua-language-server release asset."
    return 0
  fi
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/lua-language-server.tar.gz"
  curl -fsSL "$url" -o "$archive"
  mkdir -p "$tmpdir/extract"
  tar -xzf "$archive" -C "$tmpdir/extract"
  srcdir="$tmpdir/extract"
  as_root rm -rf /opt/lua-language-server
  as_root mkdir -p /opt/lua-language-server
  as_root cp -a "$srcdir"/. /opt/lua-language-server/
  symlink_bin /opt/lua-language-server/bin/lua-language-server lua-language-server
  rm -rf "$tmpdir"
}

install_zls() {
  if have zls; then
    return 0
  fi

  log "Installing ZLS"
  local regex url tmpdir archive bin
  case "$(uname -m)" in
    x86_64|amd64) regex='zls-x86_64-linux.*\.tar\.xz$' ;;
    aarch64|arm64) regex='zls-aarch64-linux.*\.tar\.xz$' ;;
    *) warn "Unsupported ZLS arch: $(uname -m)"; return 0 ;;
  esac
  url="$(latest_asset_url zigtools/zls "$regex")"
  if [ -z "$url" ]; then
    warn "Could not find zls release asset."
    return 0
  fi
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/zls.tar.xz"
  curl -fsSL "$url" -o "$archive"
  tar -xJf "$archive" -C "$tmpdir"
  bin="$(find "$tmpdir" -type f -name zls -perm -111 | sed -n '1p')"
  if [ -n "$bin" ]; then
    install_file "$bin" "$LOCAL_BIN/zls"
  else
    warn "zls binary not found in archive."
  fi
  rm -rf "$tmpdir"
}

install_go_tools() {
  if ! have go; then
    warn "go not found; skipping Go-installed tools."
    return 0
  fi

  log "Installing Go LSP/DAP tools"
  export GOPATH="${GOPATH:-/opt/go}"
  as_root mkdir -p "$GOPATH"
  as_root env GOPATH="$GOPATH" GOBIN="$LOCAL_BIN" PATH="$PATH" go install github.com/go-delve/delve/cmd/dlv@latest
  as_root env GOPATH="$GOPATH" GOBIN="$LOCAL_BIN" PATH="$PATH" go install golang.org/x/tools/gopls@latest
  as_root env GOPATH="$GOPATH" GOBIN="$LOCAL_BIN" PATH="$PATH" go install github.com/hashicorp/terraform-ls@latest
  as_root env GOPATH="$GOPATH" GOBIN="$LOCAL_BIN" PATH="$PATH" go install github.com/mrjosh/helm-ls@latest || warn "helm-ls install failed. Continuing."
}

ensure_lldb_dap_alias() {
  if have lldb-dap; then
    return 0
  fi
  if have lldb-vscode; then
    log "Creating lldb-dap compatibility symlink"
    symlink_bin "$(command -v lldb-vscode)" lldb-dap
    return 0
  fi
  local candidate
  candidate="$(find /usr/lib/llvm-* -type f \( -name lldb-dap -o -name lldb-vscode \) 2>/dev/null | sort -V | tail -n 1 || true)"
  if [ -n "$candidate" ]; then
    symlink_bin "$candidate" lldb-dap
  else
    warn "lldb-dap/lldb-vscode not found after installing lldb."
  fi
}

configure_omp_if_present() {
  if ! have omp; then
    return 0
  fi

  log "Configuring OMP tool settings"
  omp config set browser.enabled true
  omp config set browser.headless true
  omp config set lsp.enabled true
  omp config set lsp.lazy true
  omp config set lsp.diagnosticsOnWrite true
  omp config set debug.enabled true
  omp config set python.interpreter "$OMP_PYTHON_PROJECT/.venv/bin/python"
}

print_summary() {
  log "Installed tool summary"
  for bin in \
    pyright-langserver basedpyright-langserver pylsp ruff debugpy-adapter \
    typescript-language-server deno vscode-eslint-language-server \
    vscode-html-language-server vscode-css-language-server vscode-json-language-server \
    tailwindcss-language-server svelteserver vue-language-server astro-ls \
    bash-language-server shellcheck shfmt yaml-language-server docker-langserver \
    marksman texlab graphql-lsp prisma-language-server vim-language-server \
    emmet-language-server gopls zls terraform-ls lua-language-server \
    tree-sitter ast-grep dlv lldb-dap gdb clangd; do
    if have "$bin"; then
      printf '%-40s %s\n' "$bin" "$(command -v "$bin")"
    else
      printf '%-40s %s\n' "$bin" "MISSING"
    fi
  done

  if [ -x "$OMP_PYTHON_PROJECT/.venv/bin/python" ]; then
    "$OMP_PYTHON_PROJECT/.venv/bin/python" - <<'PY'
import debugpy
print(f"{'python debugpy import':<40} available")
PY
  fi
}

main() {
  require_ubuntu_2404
  install_apt_base
  install_node
  install_uv
  install_deno
  install_python_tools
  install_node_tools
  install_go_tools
  install_marksman
  install_texlab
  install_lua_language_server
  install_zls
  ensure_lldb_dap_alias
  configure_omp_if_present
  print_summary
  log "Done"
}

main "$@"
