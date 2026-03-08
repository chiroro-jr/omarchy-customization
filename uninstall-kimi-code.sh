#!/usr/bin/env bash

set -euo pipefail

UV_BIN="${UV_BIN:-uv}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
UV_TOOL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/uv/tools"

info() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

remove_path() {
  local path="$1"

  if [ -e "$path" ] || [ -L "$path" ]; then
    rm -rf "$path"
    info "Removed: $path"
  fi
}

main() {
  info "Uninstalling Kimi Code..."

  if command -v "$UV_BIN" >/dev/null 2>&1; then
    "$UV_BIN" tool uninstall kimi-cli
  else
    warn "uv is not installed; removing Kimi Code files manually."
    remove_path "$UV_TOOL_DIR/kimi-cli"
    remove_path "$BIN_DIR/kimi"
    remove_path "$BIN_DIR/kimi-cli"
  fi

  info "Kimi Code uninstalled."
}

main "$@"
