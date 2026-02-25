#!/usr/bin/env bash

set -euo pipefail

DOWNLOADS_PAGE_URL="https://paper.design/downloads"
FALLBACK_APPIMAGE_URL="https://download.paper.design/linux/appImage/x64"
ICON_URL="https://paper.design/favicon.ico"

INSTALL_DIR="$HOME/.local/share/paper"
APPIMAGE_PATH="$INSTALL_DIR/Paper.AppImage"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/paper.desktop"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
ICON_PATH="$ICON_DIR/paper.ico"

tmp_html="$(mktemp)"
tmp_appimage="$(mktemp)"
cleanup() {
  rm -f "$tmp_html" "$tmp_appimage"
}
trap cleanup EXIT

echo "Installing Paper..."

mkdir -p "$INSTALL_DIR" "$DESKTOP_DIR" "$BIN_DIR" "$ICON_DIR"

echo "Resolving latest Linux AppImage URL from ${DOWNLOADS_PAGE_URL}..."
curl -fsSL "$DOWNLOADS_PAGE_URL" -o "$tmp_html"

APPIMAGE_URL="$(
  awk 'BEGIN{IGNORECASE=1; RS="<a "; FS=">";}
    /Desktop app for Linux \(AppImage\)/ {
      if (match($1, /href="[^"]+"/)) {
        href = substr($1, RSTART + 6, RLENGTH - 7);
        print href;
        exit;
      }
    }' "$tmp_html"
)"

if [ -z "${APPIMAGE_URL:-}" ]; then
  echo "Warning: Could not parse AppImage URL from downloads page. Falling back to ${FALLBACK_APPIMAGE_URL}."
  APPIMAGE_URL="$FALLBACK_APPIMAGE_URL"
fi

case "$APPIMAGE_URL" in
  http://*|https://*) ;;
  //*) APPIMAGE_URL="https:${APPIMAGE_URL}" ;;
  /*) APPIMAGE_URL="https://paper.design${APPIMAGE_URL}" ;;
  *) APPIMAGE_URL="https://paper.design/${APPIMAGE_URL}" ;;
esac

echo "Downloading Paper AppImage..."
curl -fL --retry 3 --retry-delay 2 "$APPIMAGE_URL" -o "$tmp_appimage"

mv "$tmp_appimage" "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

echo "Downloading icon..."
curl -fsSL "$ICON_URL" -o "$ICON_PATH" 2>/dev/null || echo "Warning: Could not download icon"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Paper
Comment=Paper Desktop
Exec=$APPIMAGE_PATH
Icon=$ICON_PATH
Type=Application
Categories=Graphics;Development;
Terminal=false
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
ln -sf "$APPIMAGE_PATH" "$BIN_DIR/paper"

echo "Updating desktop database..."
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR"
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "Paper installed successfully!"
echo "Installed from: $APPIMAGE_URL"
echo "You can launch it from your application menu or by running 'paper'"
