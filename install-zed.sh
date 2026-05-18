#!/usr/bin/env bash

set -euo pipefail

REPO="zed-industries/zed"
LATEST_STABLE_RELEASE_API_URL="https://api.github.com/repos/${REPO}/releases/latest"
RELEASES_API_URL="https://api.github.com/repos/${REPO}/releases?per_page=100"
ASSET_NAME="zed-linux-x86_64.tar.gz"

INSTALL_DIR="$HOME/.local/share/zed"
APP_DIR="$INSTALL_DIR/zed.app"
VERSION_PATH="$INSTALL_DIR/version.txt"
CHANNEL_PATH="$INSTALL_DIR/channel.txt"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/dev.zed.Zed.desktop"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/zed"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
ICON_PATH="$ICON_DIR/zed.png"

RUNTIME_PACKAGES=(
  alsa-lib
  curl
  fontconfig
  glib2
  libgit2
  libxcb
  libx11
  libxkbcommon
  libxkbcommon-x11
  openbsd-netcat
  nodejs
  npm
  sqlite
  vulkan-driver
  vulkan-icd-loader
  vulkan-tools
  wayland
  zlib
  zstd
)

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

usage() {
  cat <<'EOF'
Usage: ./install-zed.sh [--channel stable|preview] [--stable|--preview]

Options:
  --channel   Select release channel explicitly (stable or preview).
  --stable    Install the latest stable release (default).
  --preview   Install the latest preview release (tag ends with -pre).
  -h, --help  Show this help message.
EOF
}

download_file() {
  local url="$1"
  local out="$2"
  local mode="${3:-quiet}"

  if command -v curl >/dev/null 2>&1; then
    if [ "$mode" = "progress" ]; then
      curl -fL --progress-bar --retry 3 --retry-delay 2 "$url" -o "$out"
    else
      curl -fsSL --retry 3 --retry-delay 2 "$url" -o "$out"
    fi
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    if [ "$mode" = "progress" ]; then
      wget --show-progress -O "$out" "$url"
    else
      wget -qO "$out" "$url"
    fi
    return
  fi

  error "curl or wget is required to download files."
}

require_python() {
  command -v python3 >/dev/null 2>&1 || error "python3 is required to parse GitHub release metadata."
}

ensure_runtime_dependencies() {
  local missing_packages=()
  local pkg

  for pkg in "${RUNTIME_PACKAGES[@]}"; do
    if ! pacman -T "$pkg" >/dev/null 2>&1; then
      missing_packages+=("$pkg")
    fi
  done

  if [ "${#missing_packages[@]}" -eq 0 ]; then
    info "All required runtime packages are already installed."
    return
  fi

  info "Installing required runtime packages: ${missing_packages[*]}"

  if command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm --needed "${missing_packages[@]}"
    return
  fi

  if command -v omarchy >/dev/null 2>&1; then
    omarchy pkg install "${missing_packages[@]}"
    return
  fi

  error "Missing runtime packages and neither yay nor omarchy is available to install them."
}

resolve_release_metadata() {
  local metadata_path="$1"
  local release_channel="$2"
  local api_url="$RELEASES_API_URL"

  if [ "$release_channel" = "stable" ]; then
    api_url="$LATEST_STABLE_RELEASE_API_URL"
  fi

  download_file "$api_url" "$metadata_path"

  python3 - "$metadata_path" "$release_channel" "$ASSET_NAME" <<'PY'
import json
import sys

path = sys.argv[1]
release_channel = sys.argv[2]
asset_name = sys.argv[3]

with open(path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)


def find_asset(release, wanted_name):
    for asset in release.get("assets", []):
        if asset.get("name") == wanted_name:
            return asset
    return None


def resolve_release(channel, data):
    if channel == "stable":
        if isinstance(data, dict):
            return data
        if isinstance(data, list):
            for release in data:
                if not release.get("prerelease", False):
                    return release
        return None

    if not isinstance(data, list):
        return None

    for release in data:
        tag = release.get("tag_name", "")
        if release.get("prerelease", False) and tag.endswith("-pre"):
            return release

    for release in data:
        if release.get("prerelease", False):
            return release

    return None


release = resolve_release(release_channel, payload)
if release is None:
    print(f"Could not find a {release_channel} release in GitHub metadata.", file=sys.stderr)
    sys.exit(1)

asset = find_asset(release, asset_name)
if asset is None:
    print(f"Asset {asset_name} was not found for release {release.get('tag_name', '<unknown>')}.", file=sys.stderr)
    sys.exit(1)

print(release["tag_name"])
print(asset["browser_download_url"])
print(asset["name"])
PY
}

write_desktop_file() {
  mkdir -p "$DESKTOP_DIR"

  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zed
GenericName=Text Editor
Comment=A high-performance, multiplayer code editor.
TryExec=$BIN_PATH
StartupNotify=true
Exec=$BIN_PATH %U
Icon=zed
Categories=Utility;TextEditor;Development;IDE;
Keywords=zed;
MimeType=text/plain;application/x-zerosize;x-scheme-handler/zed;
Actions=NewWorkspace;

[Desktop Action NewWorkspace]
Exec=$BIN_PATH --new %U
Name=Open a new workspace
EOF
}

main() {
  local release_channel tmp_dir metadata_path tmp_archive tag archive_url archive_name current_version current_channel

  release_channel="stable"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --channel)
        if [ "$#" -lt 2 ]; then
          error "--channel requires a value: stable or preview"
        fi

        case "$2" in
          stable|preview)
            release_channel="$2"
            ;;
          *)
            error "Invalid --channel value: $2 (expected: stable or preview)"
            ;;
        esac
        shift
        ;;
      --stable)
        release_channel="stable"
        ;;
      --preview)
        release_channel="preview"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        ;;
    esac
    shift
  done

  require_python
  ensure_runtime_dependencies

  tmp_dir="$(mktemp -d)"
  trap "rm -rf '$tmp_dir'" EXIT

  metadata_path="$tmp_dir/release.json"

  if [ "$release_channel" = "preview" ]; then
    info "Resolving latest Zed preview release from ${RELEASES_API_URL}..."
  else
    info "Resolving latest Zed stable release from ${LATEST_STABLE_RELEASE_API_URL}..."
  fi

  mapfile -t release_data < <(resolve_release_metadata "$metadata_path" "$release_channel")

  if [ "${#release_data[@]}" -lt 3 ]; then
    error "Could not resolve the latest ${release_channel} Zed archive asset."
  fi

  tag="${release_data[0]}"
  archive_url="${release_data[1]}"
  archive_name="${release_data[2]}"

  mkdir -p "$INSTALL_DIR" "$DESKTOP_DIR" "$BIN_DIR" "$ICON_DIR"

  current_version=""
  current_channel=""
  if [ -f "$VERSION_PATH" ]; then
    current_version="$(cat "$VERSION_PATH")"
  fi
  if [ -f "$CHANNEL_PATH" ]; then
    current_channel="$(cat "$CHANNEL_PATH")"
  fi

  if [ "$current_version" = "$tag" ] && [ "$current_channel" = "$release_channel" ]; then
    info "Installed version already matches selected release (${tag}, ${release_channel}). Reinstalling to refresh local files."
  else
    info "Updating Zed from ${current_version:-not installed}${current_channel:+ (${current_channel})} to ${tag} (${release_channel})."
  fi

  tmp_archive="$tmp_dir/$archive_name"

  info "Downloading ${archive_name}..."
  download_file "$archive_url" "$tmp_archive" "progress"

  rm -rf "$APP_DIR"
  tar -xzf "$tmp_archive" -C "$INSTALL_DIR"

  [ -x "$APP_DIR/bin/zed" ] || error "Expected Zed binary was not found at $APP_DIR/bin/zed after extraction."
  [ -f "$APP_DIR/share/icons/hicolor/512x512/apps/zed.png" ] || warn "Expected Zed icon was not found in the extracted archive."

  printf '%s\n' "$tag" > "$VERSION_PATH"
  printf '%s\n' "$release_channel" > "$CHANNEL_PATH"

  if [ -f "$APP_DIR/share/icons/hicolor/512x512/apps/zed.png" ]; then
    cp "$APP_DIR/share/icons/hicolor/512x512/apps/zed.png" "$ICON_PATH"
  fi

  chmod +x "$APP_DIR/bin/zed"
  ln -sf "$APP_DIR/bin/zed" "$BIN_PATH"
  write_desktop_file
  chmod +x "$DESKTOP_FILE"

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  fi

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi

  if pacman -Q zed >/dev/null 2>&1 || pacman -Q zed-preview >/dev/null 2>&1; then
    warn "A pacman-managed Zed package is also installed. ~/.local/bin/zed should take precedence, but consider removing the repo/AUR package to avoid confusion."
  fi

  info "Zed installed successfully."
  info "Channel: ${release_channel}"
  info "Version: ${tag}"
  info "Source: ${archive_url}"
  info "Run 'zed' or launch it from your application menu."
}

main "$@"
