#!/bin/sh
set -e

DOTFILES_DIR="$HOME/dotfiles"
VSCODE_INSIDERS_DIR="$HOME/.config/Code - Insiders/User"

mkdir -p "$VSCODE_INSIDERS_DIR"

ln -sf "$DOTFILES_DIR/vscode-insiders/settings.json" "$VSCODE_INSIDERS_DIR/settings.json"
ln -sf "$DOTFILES_DIR/vscode-insiders/keybindings.json" "$VSCODE_INSIDERS_DIR/keybindings.json"
