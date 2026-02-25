#!/usr/bin/env bash

set -euo pipefail

UPSTREAM_INSTALL_URL="${CODEX_UPSTREAM_INSTALL_URL:-https://raw.githubusercontent.com/ilysenko/codex-desktop-linux/main/install.sh}"
UPSTREAM_INSTALL_FALLBACK_URL="https://github.com/ilysenko/codex-desktop-linux/raw/main/install.sh"
INSTALL_DIR="${CODEX_APP_INSTALL_DIR:-$HOME/.local/share/codex-app}"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/codex-app.desktop"
BIN_DIR="$HOME/.local/bin"
WRAPPER_BIN="$BIN_DIR/codex-app"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
ICON_PATH="$ICON_DIR/codex-app.png"
ICON_URL="${CODEX_APP_ICON_URL:-https://raw.githubusercontent.com/ilysenko/codex-desktop-linux/main/codex.png}"

info() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
  exit 1
}

download_file() {
  local url="$1"
  local out="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 --retry-delay 2 "$url" -o "$out"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
    return
  fi

  error "curl or wget is required to download files."
}

install_missing_dependencies() {
  local missing=()
  local cmd

  for cmd in node npm npx python3 7z unzip make g++; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    return
  fi

  warn "Missing dependencies: ${missing[*]}"
  info "Attempting package installation..."

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y nodejs npm python3 p7zip-full curl unzip build-essential
    return
  fi

  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y nodejs npm python3 p7zip p7zip-plugins curl unzip make gcc-c++
    return
  fi

  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm nodejs npm python p7zip curl unzip base-devel
    return
  fi

  if command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install nodejs20 npm20 python3 p7zip curl unzip make gcc-c++
    return
  fi

  error "Could not auto-install dependencies. Install these manually: node npm npx python3 7z unzip make g++"
}

verify_dependencies() {
  local missing=()
  local cmd

  for cmd in node npm npx python3 7z unzip make g++; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    error "Still missing dependencies after install attempt: ${missing[*]}"
  fi

  local node_major
  node_major="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
  if [ "$node_major" -lt 20 ]; then
    error "Node.js 20+ is required (found $(node -v))."
  fi
}

run_upstream_installer() {
  local upstream_script
  upstream_script="$(mktemp)"

  info "Downloading upstream installer: $UPSTREAM_INSTALL_URL"
  if ! download_file "$UPSTREAM_INSTALL_URL" "$upstream_script"; then
    warn "Primary upstream URL failed, trying fallback: $UPSTREAM_INSTALL_FALLBACK_URL"
    download_file "$UPSTREAM_INSTALL_FALLBACK_URL" "$upstream_script"
  fi

  chmod +x "$upstream_script"
  info "Running upstream installer into: $INSTALL_DIR"
  CODEX_INSTALL_DIR="$INSTALL_DIR" bash "$upstream_script" "${1:-}"
}

write_wrapper() {
  mkdir -p "$BIN_DIR"

  cat > "$WRAPPER_BIN" <<EOF
#!/usr/bin/env bash
set -euo pipefail

exec "$INSTALL_DIR/start.sh" "\$@"
EOF

  chmod +x "$WRAPPER_BIN"
}

install_icon() {
  local local_icon

  mkdir -p "$ICON_DIR"

  # Prefer icon assets extracted by the upstream installer.
  if [ -d "$INSTALL_DIR/content/webview/assets" ]; then
    shopt -s nullglob
    for local_icon in "$INSTALL_DIR"/content/webview/assets/app-*.png "$INSTALL_DIR"/content/webview/assets/logo-*.png; do
      if [ -f "$local_icon" ]; then
        cp -f "$local_icon" "$ICON_PATH"
        shopt -u nullglob
        return
      fi
    done
    shopt -u nullglob
  fi

  # Fallback for older/newer upstream layouts.
  if ! download_file "$ICON_URL" "$ICON_PATH" >/dev/null 2>&1; then
    warn "Could not install icon from local assets or $ICON_URL"
  fi
}

write_desktop_file() {
  mkdir -p "$DESKTOP_DIR"

  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=Codex App
Comment=Codex Desktop App
Exec=$WRAPPER_BIN %U
TryExec=$WRAPPER_BIN
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=x-scheme-handler/codex;
StartupWMClass=codex
StartupNotify=true
EOF
}

register_protocol_handler() {
  if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "$(basename "$DESKTOP_FILE")" x-scheme-handler/codex || warn "xdg-mime URL handler registration failed"
  else
    warn "xdg-mime not found; skipping codex:// protocol registration"
  fi

  if command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-url-scheme-handler codex "$(basename "$DESKTOP_FILE")" || true
  fi
}

refresh_desktop_caches() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" || true
  fi

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi
}

main() {
  local integrate_only=0
  local dmg_path=""

  if [ "${1:-}" = "--integrate-only" ]; then
    integrate_only=1
    shift
  fi

  dmg_path="${1:-}"

  if [ "$integrate_only" -eq 0 ] && [ "${CODEX_SKIP_UPSTREAM_INSTALL:-0}" != "1" ]; then
    install_missing_dependencies
    verify_dependencies
    run_upstream_installer "$dmg_path"
  fi

  [ -x "$INSTALL_DIR/start.sh" ] || error "Codex app not found at $INSTALL_DIR/start.sh"

  install_icon
  write_wrapper
  write_desktop_file
  register_protocol_handler
  refresh_desktop_caches

  info "Codex App installation finished."
  info "Launcher command: $WRAPPER_BIN"
  info "Desktop entry: $DESKTOP_FILE"

  if ! command -v codex >/dev/null 2>&1; then
    warn "Codex CLI was not found. Install it with: npm i -g @openai/codex"
  fi
}

main "$@"
