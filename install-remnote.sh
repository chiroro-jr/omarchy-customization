#!/usr/bin/env bash

set -euo pipefail

APPIMAGE_URL="https://backend.remnote.com/desktop/linux"
ICON_URL="https://www.remnote.com/favicon.ico"

INSTALL_DIR="$HOME/.local/share/remnote"
APPIMAGE_PATH="$INSTALL_DIR/RemNote.AppImage"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/remnote.desktop"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
ICON_PATH="$ICON_DIR/remnote.ico"

tmp_appimage="$(mktemp)"
cleanup() {
  rm -f "$tmp_appimage"
}
trap cleanup EXIT

echo "Installing RemNote..."

mkdir -p "$INSTALL_DIR" "$DESKTOP_DIR" "$BIN_DIR" "$ICON_DIR"

echo "Downloading RemNote AppImage from ${APPIMAGE_URL}..."
curl -fL --retry 3 --retry-delay 2 "$APPIMAGE_URL" -o "$tmp_appimage"

mv "$tmp_appimage" "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

echo "Downloading icon..."
curl -fsSL "$ICON_URL" -o "$ICON_PATH" 2>/dev/null || echo "Warning: Could not download icon"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=RemNote
Comment=All-in-one workspace for thinking and learning
Exec=$APPIMAGE_PATH %U
Icon=$ICON_PATH
Type=Application
Categories=Education;Office;
Terminal=false
StartupNotify=true
StartupWMClass=RemNote
MimeType=x-scheme-handler/remnote;x-scheme-handler/rn;
EOF

chmod +x "$DESKTOP_FILE"
ln -sf "$APPIMAGE_PATH" "$BIN_DIR/remnote"

echo "Registering protocol handlers..."
if command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default remnote.desktop x-scheme-handler/remnote x-scheme-handler/rn
fi

echo "Updating desktop database..."
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR"
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "RemNote installed successfully!"
echo "You can launch it from your application menu or by running 'remnote'"
