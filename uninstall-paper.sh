#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/paper"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/paper.desktop"
BIN_PATH="$HOME/.local/bin/paper"
ICON_PATH="$HOME/.local/share/icons/hicolor/256x256/apps/paper.ico"

echo "Uninstalling Paper..."

if [ -d "$INSTALL_DIR" ]; then
  echo "Removing $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
fi

if [ -f "$DESKTOP_FILE" ]; then
  echo "Removing $DESKTOP_FILE..."
  rm -f "$DESKTOP_FILE"
fi

if [ -L "$BIN_PATH" ] || [ -f "$BIN_PATH" ]; then
  echo "Removing $BIN_PATH..."
  rm -f "$BIN_PATH"
fi

if [ -f "$ICON_PATH" ]; then
  echo "Removing $ICON_PATH..."
  rm -f "$ICON_PATH"
fi

echo "Updating desktop database..."
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

echo "Paper uninstalled successfully!"
