#!/usr/bin/env bash

set -euo pipefail

DOWNLOAD_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.0-6324554176528384/linux-x64/Antigravity.tar.gz"
ICON_URL="https://antigravity.google/assets/image/antigravity-logo.png"
INSTALL_DIR="$HOME/.local/share/antigravity"
APP_DIR="$INSTALL_DIR/Antigravity-x64"
VERSION_PATH="$INSTALL_DIR/version.txt"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/antigravity"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/antigravity.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
ICON_PATH="$ICON_DIR/antigravity.png"

info() {
  echo "[INFO] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "$1 is required."
}

download_file() {
  local url="$1"
  local out="$2"

  curl -fL --compressed --progress-bar --retry 3 --retry-delay 2 "$url" -o "$out"
}

version_from_url() {
  printf '%s' "$DOWNLOAD_URL" | sed -n 's#.*/antigravity-hub/\([^/]*\)/linux-x64/.*#\1#p'
}

write_desktop_file() {
  mkdir -p "$DESKTOP_DIR"

  cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity
GenericName=Text Editor
Exec=$BIN_PATH %F
Icon=$ICON_PATH
Type=Application
StartupNotify=true
StartupWMClass=Antigravity
Categories=Development;IDE;TextEditor;
MimeType=text/plain;inode/directory;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$BIN_PATH --new-window %F
EOF

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  fi
}

refresh_icon_cache() {
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi
}

usage() {
  cat <<EOF
Usage: ./install-antigravity.sh

Installs Google Antigravity from:
  $DOWNLOAD_URL
EOF
}

install_antigravity() {
  local version current_version tmp archive extracted_dir

  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    "") ;;
    *) error "Unknown option: $1" ;;
  esac

  require_command curl
  require_command sed
  require_command tar

  if [ "$(uname -m)" != "x86_64" ]; then
    error "This direct Antigravity link is only for linux-x64. Current architecture: $(uname -m)"
  fi

  version="$(version_from_url)"
  [ -n "$version" ] || error "Could not parse Antigravity version from: $DOWNLOAD_URL"

  if [ -f "$VERSION_PATH" ]; then
    current_version="$(cat "$VERSION_PATH")"
    if [ "$current_version" = "$version" ] && [ -x "$BIN_PATH" ]; then
      mkdir -p "$ICON_DIR"
      download_file "$ICON_URL" "$ICON_PATH"
      write_desktop_file
      refresh_icon_cache
      info "Antigravity $version is already installed. Refreshed desktop launcher."
      exit 0
    fi
  fi

  info "Installing Antigravity $version..."
  tmp="$(mktemp -d)"
  trap "rm -rf '$tmp'" EXIT

  archive="$tmp/antigravity.tar.gz"
  download_file "$DOWNLOAD_URL" "$archive"

  tar -xzf "$archive" -C "$tmp"
  extracted_dir="$tmp/Antigravity-x64"
  [ -d "$extracted_dir" ] || error "Downloaded archive did not contain the expected Antigravity-x64 directory."

  mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$ICON_DIR"
  rm -rf "$APP_DIR"
  mv "$extracted_dir" "$APP_DIR"

  ln -sfn "$APP_DIR/antigravity" "$BIN_PATH"
  printf '%s\n' "$version" >"$VERSION_PATH"

  download_file "$ICON_URL" "$ICON_PATH"
  write_desktop_file
  refresh_icon_cache

  info "Installed Antigravity $version"
  info "Binary: $BIN_PATH"
}

install_antigravity "$@"
