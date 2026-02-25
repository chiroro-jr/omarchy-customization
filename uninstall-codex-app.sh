#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${CODEX_APP_INSTALL_DIR:-$HOME/.local/share/codex-app}"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/codex-app.desktop"
BIN_FILE="$HOME/.local/bin/codex-app"
ICON_FILE="$HOME/.local/share/icons/hicolor/512x512/apps/codex-app.png"

MIME_FILES=(
  "$HOME/.config/mimeapps.list"
  "$HOME/.local/share/applications/mimeapps.list"
)

PURGE_USER_DATA=0

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

remove_codex_handler_from_mimeapps() {
  local mime_file="$1"
  local tmp

  [ -f "$mime_file" ] || return

  tmp="$(mktemp)"
  awk '
    function trim(v) {
      sub(/^[[:space:]]+/, "", v)
      sub(/[[:space:]]+$/, "", v)
      return v
    }
    {
      if ($0 ~ /^x-scheme-handler\/codex=/) {
        split($0, kv, "=")
        n = split(kv[2], entries, ";")
        out = ""
        for (i = 1; i <= n; i++) {
          entry = trim(entries[i])
          if (entry == "" || entry == "codex-app.desktop") {
            continue
          }
          if (out == "") {
            out = entry
          } else {
            out = out ";" entry
          }
        }
        if (out != "") {
          print kv[1] "=" out ";"
        }
        next
      }
      print
    }
  ' "$mime_file" > "$tmp"

  mv "$tmp" "$mime_file"
  info "Updated: $mime_file"
}

refresh_desktop_caches() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" || true
  fi

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi
}

purge_user_data() {
  local path
  local data_paths=(
    "$HOME/.config/Codex"
    "$HOME/.config/codex"
    "$HOME/.cache/Codex"
    "$HOME/.cache/codex"
    "$HOME/.local/share/Codex"
    "$HOME/.local/share/codex"
  )

  for path in "${data_paths[@]}"; do
    remove_path "$path"
  done
}

main() {
  local mime_file

  if [ "${1:-}" = "--purge-user-data" ]; then
    PURGE_USER_DATA=1
  elif [ -n "${1:-}" ]; then
    echo "Usage: $0 [--purge-user-data]" >&2
    exit 1
  fi

  info "Uninstalling Codex App..."

  remove_path "$INSTALL_DIR"
  remove_path "$DESKTOP_FILE"
  remove_path "$BIN_FILE"
  remove_path "$ICON_FILE"

  for mime_file in "${MIME_FILES[@]}"; do
    remove_codex_handler_from_mimeapps "$mime_file"
  done

  refresh_desktop_caches

  if [ "$PURGE_USER_DATA" -eq 1 ]; then
    purge_user_data
  else
    warn "User data was kept. Re-run with --purge-user-data to remove local Codex data."
  fi

  info "Codex App uninstalled."
}

main "$@"
